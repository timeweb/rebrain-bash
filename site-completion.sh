#!/usr/bin/env bash

gen_comp_words() {
    # $1 is string with opts.
    all_words="$1"

    # Find matched wordss.
    used_words="$(echo "${COMP_WORDS[@]} $all_words" \
        | tr ' ' '\n' | sort | uniq -d \
    )"

    if [ "$used_words" ]
    then
        # Delete 'help' option.
        all_words="$(sed 's%--help%%;s%-h%%' <<< $all_words)"

        # Delete words if match.
        for opt in $used_words
        do
            all_words="$(sed "s%$opt%%" <<< $all_words)"
        done
    fi

    echo "$all_words"
}

_site() {
#    COMPREPLY=($(compgen -W \
#        "-v --version -h --help --disabled --no-dir
#        -e --edit -y -t --template" -- "${COMP_WORDS[COMP_CWORD]}"))
    cw="$(gen_comp_words "-v --version -h --help --disabled --no-dir
        -e --edit -y -t --template")"
    COMPREPLY=($(compgen -W \
     "$cw" -- "${COMP_WORDS[COMP_CWORD]}"))
}

complete -F _site site
