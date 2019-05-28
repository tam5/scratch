# Helper functions

#
# Set trap to abort script
#
lay_traps () {
    trap "print_line;
          print_line;
          print_color red '🥊 Aborted';
          print_line;
          stop_spinner $? &> /dev/null;
          exit 130" INT
}

#
# Check if an array contains a value
# @param $1 the needle
# @param $2 the haystack
#
array_contains () {
    local seeking=$1; shift
    local in=1
    for element; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

#
# Check if the current git branch is dirty, and echo a * if it is
#
is_git_dirty () {
  [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && echo "*"
}

#
# Get the currently checked out git branch of an app
# @param $1 the app
#
get_git_branch () {
    app=$1
    if ! assert_app $app &> /dev/null; then return 0; fi

    cd apps/$1
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref=" ➦ ($(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    branch="${ref/refs\/heads\//  }"$(is_git_dirty)

    echo $branch
}

#
# Determine Operating System
#
determine_os () {
    case "$OSTYPE" in
        "darwin"*) echo "mac";;
        "linux"*) echo "linux";;
        "msys"*) echo "windows";;
        \?) echo "unknown" ;;
    esac
}
