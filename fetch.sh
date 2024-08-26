cwd=${1:-./}

# usage: scan_dir <path>
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
        .ssh|.config)             continue;;
        bin|share|lib|scripts)    continue;;
        esac
        #
        table="${table:+$table }$dir"
    done
    test -n $cwd && cd - >/dev/null 2>&1
    echo $table
}

# usage: git_check <repo>
git_check() {
	local repo=$1 ret
	test -d $repo || return 1
	cd $repo || return 1
    ret=$(git rev-parse --is-bare-repository 2>/dev/null)
    cd - >/dev/null
	case $ret in
	true)	return 0;;
	*)		return 1;;
	esac
}

# usage: dir_check <path>
dir_check() {
    local cwd=${1:-./}; cwd=${cwd%/}
    local dir dirs git repos table
    dirs=$(scan_dir $cwd)
    for dir in $dirs; do
		git_check $cwd/$dir; ret=$?
		echo "check $cwd/$dir ret:$ret" >> ~/result

		case $ret in
		0) repos=${repos:+$repos }$cwd/$dir;;
		*) table=${table:+$table }$cwd/$dir;;
		esac
    done
    echo "git:$repos"
    echo "dir:$table"
}

# usage: _scan_git <idx> <path>...
_scan_git() {
    local idx=$1; shift
    local cwd result repos table
    for cwd in $@; do
        result=$(dir_check $cwd)
        repos=${repos:+$repos }$(echo "$result" | sed -nre 's/^git:(.*)/\1/p')
        table=${table:+$table }$(echo "$result" | sed -nre 's/^dir:(.*)/\1/p')
    done
    test -n "$repos" && echo "git:$repos"
    test -n "$table" && echo "dir:$table"
}

# usage: scan_git <path>...
scan_git() {
    local table=$@ i result repos table git
    for i in $(seq 1 1 ${SCAN_DEPTH:-4}); do
        result=$(_scan_git $i $table)
        repos=$(echo "$result" | sed -nre 's/^git:(.*)/\1/p')
        table=$(echo "$result" | sed -nre 's/^dir:(.*)/\1/p')
        test -n "$repos" && git=${git:+$git }$repos
        test -n "$table" || break
    done
	test -n "$git" && echo $git
}



git_remote_get_url() {
	local repo=$1
	git_check $repo || continue
	cd "$repo" || continue
	#
	origin=$(git remote | head -n 1)


}


# git_fetch <repo>...
git_fetch() {
	for repo in "$@"; do
        git_check $repo || continue
		cd "$repo" || continue
		#
		origin=$(git remote | head -n 1)
        test -n "$origin" || { echo -e "\e[33mThe $repo doesn't have remote!\e[0m"; cd - >/dev/null; continue; }
        echo -e "\e[32mFetch from $origin in $repo ...\e[0m"
		git fetch $origin *:*
		#
		cd - >/dev/null
	done
}

repos=$(scan_git $cwd)
repo_cnt=$(echo $repos | wc -w)

#
for git in $repos; do
    git_fetch $git
done


