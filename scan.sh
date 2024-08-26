cwd=${1:-./}
depth=3

scan_dir() {
	local cwd=$1 dir dirs table
	test -n $cwd && cd $cwd
	dirs=$(find ./ -mindepth 1 -maxdepth 1 -type d)
	#
	for dir in ${dirs}; do
		dir=${dir#./}
		test -d $dir || continue
		#
		case $dir in
		.ssh|.config)
			continue
		;;
		scripts)
			continue
		;;
		esac
		#
		table="${table:+$table }$dir"
	done
	test -n $cwd && cd - >/dev/null 2>&1
	echo $table
}

check_git() {
	local cwd=${1:-./}; cwd=${cwd%/}
	local dir dirs git repos table
	dirs=$(scan_dir $cwd)
	for dir in $dirs; do
		#
		cd $cwd/$dir
		git=$(git rev-parse --is-bare-repository 2>/dev/null)
		cd - >/dev/null 2>&1
		#
		if [ "$git" = "true" ]; then
			repos=${repos:+$repos }$cwd/$dir
			continue
		fi
		#
		table=${table:+$table }$cwd/$dir
	done
	echo "git:$repos"
	echo "dir:$table"
}

#
_scan_git() {
	local idx=$1; shift
	local cwd result repos table
	for cwd in $@; do
		result=$(check_git $cwd)
		repos=${repos:+$repos }$(echo "$result" | sed -nre 's/^git:(.*)/\1/p')
		table=${table:+$table }$(echo "$result" | sed -nre 's/^dir:(.*)/\1/p')
	done
	test -n "$repos" && echo "git:$repos"
	test -n "$table" && echo "dir:$table"
}

#
scan_git() {
	local table=$@ i result repos table
	for i in $(seq 1 1 ${SCAN_DEPTH:-4}); do
		result=$(_scan_git $i $table)
		repos=$(echo "$result" | sed -nre 's/^git:(.*)/\1/p')
		table=$(echo "$result" | sed -nre 's/^dir:(.*)/\1/p')
		test -n "$repos" && REPOS=${REPOS:+$REPOS }$repos
		test -n "$table" || break
	done
}

scan_git $cwd

idx=0
for git in $REPOS; do idx=$((idx + 1))
	printf "%02d - %s\n" $idx $git
done
