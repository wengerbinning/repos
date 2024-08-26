#!/bin/bash

WORKDIR=${HOME}

test -f .config/proxy && source .config/proxy

# =========================================================================== #

# usage: git_check <repo>
git_check() {
	local repo=$1
	local ret
	test -d $repo  && cd $repo && {
		ret=$(git rev-parse --is-bare-repository 2>/dev/null)
		cd - >/dev/null 2>&1
	}
	case $ret in
	true)	return;;
	esac
	return 1
}

# usage: git_scan <path>
git_scan () {
    local path=$@
	for dir in "$@"; do
		for path in $(find $dir -type d -name '*.git'); do
			git_check $path && echo $path || continue
		done
	done
}

# git_fetch <repo>...
git_fetch () {
	for repo in "$@"; do
        git_check $repo && cd "$repo" && {
			origin=$(git remote show origin 2>/dev/null | sed -nre 's/Fetch URL: (.*)/\1/p')
			origin="$(echo $origin)"
        	test -n "$origin" || {
				echo -e "\e[33mthe ${repo#$HOME/} not remote\e[0m";
				continue;
			};

        	#
			echo -e "\e[32mfetch ${repo#$HOME/} from $origin ...\e[0m"
			git fetch $origin *:*
			#
			cd - >/dev/null 2>&1
		}
	done
}

# =========================================================================== #

SCRIPT_DESC="
This is repository managerment tools.

repos <COMMAND>



COMMAND:
    fetch   fetch remote repository
    list    list all repositoy
"

cmd=$1; shift
case $cmd in
list)
	git_scan ${1:-$WORKDIR}
    ;;
fetch)
	git_fetch $(git_scan  ${1:-$WORKDIR} | xargs)
	;;
*)
    echo "$SCRIPT_DESC"
esac


