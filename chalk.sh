# Helper functions for writing pretty messages to the console.

# Colors
end="\033[0m"
black="\033[0;30m"
blackb="\033[1;30m"
white="\033[0;37m"
whiteb="\033[1;37m"
red="\033[0;31m"
redb="\033[1;31m"
green="\033[0;32m"
greenb="\033[1;32m"
yellow="\033[0;33m"
yellowb="\033[1;33m"
blue="\033[0;34m"
blueb="\033[1;34m"
purple="\033[0;35m"
purpleb="\033[1;35m"
lightblue="\033[0;36m"
lightblueb="\033[1;36m"

problems=()

function print_line {
    echo >&2 "$@";
}

function print_work {
    if [[ "$1" == "-n" ]]; then
        shift
        n="-n"
    else
        n=""
    fi

    print_color white $n ">  $@"
}

function print_color {
    color=$1

    if [[ "$2" == "-n" ]]; then
        shift 2
        printf >&2 "${!color}$@${end}";
    elif [[ "$2" == "-e" ]]; then
        shift 2
        echo -e "${!color}$@${end}";
    else
        shift
        echo -e >&2 "${!color}$@${end}";
    fi
}

function list_issue {
    (
        print_color yellow "🧩  $@"
        print_line
    ) 2> /dev/null 2>&1
}

function list_issue_extra {
    (
        print_line
        print_color yellow "   $@"
        print_line
    ) 2> /dev/null 2>&1
}

function list_solution {
    (
        print_color whiteb "        $@"
    ) 2> /dev/null 2>&1
}

function list_check {
    print_color green "✓  $@"
}

function give_award {
    print_color green "🏅 $@"
}

function give_dynamite {
    print_color red "🧨  $@"
}

function indenter {
    sed 's/^/>  /' >&2
}

function abort_message {
    print_line
    print_color redb "   The installer cannot continue and will now quit. Please follow the instructions here:"
    print_color redb "   https://github.com/LiveIntent/dockerized-platform/blob/master/docs/manual-installation.md"
    print_color redb "   to install the platformer manually."
    print_line
}

function show_description {
    (
        print_color yellow "Description:"
        print_line "   $@"
        print_line
    ) 2> /dev/null 2>&1
}

function show_usage {
    new_line=print_line
    if [[ "$1" == "-n" ]]; then
        shift 1
        new_line=""
    fi

    (
        print_color yellow "Usage:"
        print_line "   $@"
        $($new_line)
    ) 2> /dev/null 2>&1
}

function show_usage_extra {
    (
        print_line "   $@"
        print_line
    ) 2> /dev/null 2>&1
}

function show_option_flags_first {
    (
        print_color yellow "Options:"
        print_color green -n "   $@"
    ) 2> /dev/null 2>&1
}

function show_option_flags {
    (
        print_color green -n "   $@"
    ) 2> /dev/null 2>&1
}

function show_option_text {
    (
        print_color white "          $@"
    ) 2> /dev/null 2>&1
}
