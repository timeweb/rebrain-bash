#!/usr/bin/env bash

set -o errexit

print_help() {
cat << EOF
Usage:
    $0 [--help] [--foo=<value>] [--bar=<value>...] [-f] [-b]
    [--multi <value>...] [<command>] [<arguments>]

Commands:
    foobar              some subcommand.

Options:
    --foo=<value>       proc foo option.
    --bar=<value>...    proc bar option with multiple values.
    -f                  proc f flag.
    -b                  proc b flag.
    --multi <value>...  proc multivalue option.
    --help              print this message and exit.
EOF
exit 0
}

get_optarg() {
    if [[ "$1" =~ .+=.+ ]]; then
        opt="${1%%=*}"; arg="${1#*=}"; sft=1
    elif [[ ! "$1" =~ .+=$ ]] && \
         [ "$2" ] && [ "${2:0:1}" != '-' ]
    then
        opt="$1"; arg="$2"; sft=2
    else
        opt="$1"
        if [[ "$1" =~ .+=$ ]]; then opt="${1:0: -1}"; fi
        echo "$0: Missing argument for: $opt" >&2
        exit 1
    fi
}

spin() {
    ppid="$1"
    message="$2"
    delay=.1
    chars="/-\|*"

    tput civis  # Hide cursor.
    while [ -d /proc/$ppid ]
    do
        for (( i=0; i<${#chars}; i++ )); do
            sleep "$delay"
            echo -en "[ ${chars:$i:1} ] $message" "\r"
        done
    done
    echo -e "[ Done ] $message"
    tput cnorm  # Bring cursor back.
}

foobar() {
local help="
Usage:
    $0 foobar [--help] [<command>] [<options>]

Commands and options:
    spin <time>     spin amount time in seconds.
    --help          show this message and exit.
"
    if [[ ! "$@" ]];then
        echo "$help"; exit 0
    fi

    while (( "$#" ))
    do
        case "$1" in
            spin)
                sp=1;  # spin
                if [ "$2" ] && [ "${2:0:1}" != '-' ]
                then
                    tm="$2"
                    shift
                fi
                shift
                ;;
            --help) echo "$help"; exit 0;;
        esac
    done

    if [ "$sp" ]
    then
        sleep "$tm" &
        spin "$!" "Spinning $tm seconds"
    fi
}

[[ "$@" ]] || print_help

while (( "$#" ))
do
    case "$1" in
        foobar)
            # Command.
            shift; foobar "$@"; shift "$#";;
        --multi)
            opt="$1"; shift  # Save option name and shift.
            while (( "$#" ))
            do
                if [[ "$1" =~ ^--$ ]]
                then
                    eop=1; shift  # End of the options.
                elif [[ "$1" =~ ^-$|--.+|-[^-]+ ]] && [ ! "$eop" ]
                then
                    echo \
                    "$0: Only positional arguments allowed after $opt" >&2
                    echo \
                    "Use -- (end of opts) for allow options as arguments."
                    exit 1
                fi
                multi+=("$1"); shift
            done
            ;;
        --help)
            print_help;;
        --)
            # End of the options.
            # Save all following options as positional arguments.
            shift; args+=("$@")
            shift "$#"
            ;;
        --foo|--foo=*)
            get_optarg "$1" "$2"
            foo+=("$arg")  # Single value.
            shift "$sft";;
        --bar|--bar=*)
            get_optarg "$1" "$2"
            # Multiple values.
            # Accept single value if it passed with '='.
            bar+=("$arg")
            if [ "$bar" == "$2" ]
            then
                shift 2 # Shift for prevent doublicate first value
                        # and option name. I.e. skip this: --bar A
                while (( "$#" ))
                do
                    if [[ ! "$1" =~ ^-+ ]]
                    then
                        bar+=("$1"); shift
                    else
                        break
                    fi
                done
                sft=0  # Don't shift after parser to prevent
                       # next argument skipping.
            fi
            shift "$sft";;
        -*)
            # Short options. -abc as -a -b -c
            # Split $1 to characters.
            for i in $(seq 2 ${#1}); do opts+=("-${1:i-1:1}"); done

            for opt in "${opts[@]}"
            do
                case "$opt" in
                    -f) f=1;;
                    -b) b=1;;
                    *) echo "$0: Bad option: $opt" >&2; exit 1;;
                esac
            done
            shift
            ;;
        *)
            args+=("$1")  # Save positional arguments.
            shift
            ;;
    esac
done

[ "$foo" ]   && echo "Proc foo: <${foo[@]}>"
[ "$bar" ]   && echo "Proc bar: <${bar[@]}>"
[ "$f" ]     && echo "Proc f: <$f>"
[ "$b" ]     && echo "Proc b: <$b>"
[ "$multi" ] && echo "Proc multi: <${multi[@]}>"
[ "$args" ]  && echo "Positional: <${args[@]}>"
