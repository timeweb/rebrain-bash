#!/usr/bin/env bash

set -o errexit  # Exit if error occurs.

version=0.1
web_root=/srv
templates_dir=/etc/site.conf.d

##########################################################################

set_domain() {
    while true
    do
        echo -n "Domain name: "
        read -r
        if [ "$REPLY" ]; then
            if yn_dialog "Proceed with this domain? $REPLY"
            then
                domain_name="$REPLY"
                break
            fi
        fi
    done

}

check_vhost() {
    if [ -f /etc/nginx/sites-available/$domain_name ]
    then
        echo "Virtual host for $domain_name already exists!"
        if yn_dialog "Do you want to replace it?"
        then
            :  # Do nothing. Vhost will be replaced.
        else
            echo Abort.
            exit 1
        fi
    fi
}

select_template() {
    # Get available vhost template list.
    for vh in $(find "$templates_dir" -type f -name "*.vhost")
    do
        vhosts+=("${vh##*\/}")
    done

    if [[ "${#vhosts[@]}" == '0' ]]; then
        echo "$0: No vhost templates found in $templates_dir" >&2
        exit 1
    fi

    PS3='Enter a number: '  # Select prompt.

    echo 'Select virtual host template:'
    select val in ${vhosts[@]}
    do
        if [ "$val" ]
        then
            template="$templates_dir/$val"
            break
        else
            echo 'Bad value. Try again or press ^C to cancel.'
        fi
    done

    echo "Selected template: $template"
}

create_site_dir() {
    local site_dir="$web_root/$domain_name/public"
    mkdir -p "$site_dir"
    # Add stub
    if [ ! -f "$site_dir" ]
    then
        echo "$domain_name is created!" > "$site_dir"/index.html
    fi
    echo -e " -> Create root directory: $site_dir"
}

create_vhost() {
    vhost=/etc/nginx/sites-available/$domain_name

    if [ -f "$template" ]
    then
        cp "$template" "$vhost"
    else
        echo "Template not found: $template" >&2
        exit 1
    fi

    # Replace template data with actual data.
    #+Deafult placeholder in configs is 'example.org'.
    sed -i "s%example\.org%$domain_name%g" "$vhost"

    echo " -> Create virtual host: $vhost"
}

enable_vhost() {
    symlink="$(sed 's%available%enabled%' <<< "$vhost")"
    [ -f "$symlink" ] && rm "$symlink"
    ln -s "$vhost" /etc/nginx/sites-enabled/

    echo " -> Create symlink: $symlink -> $vhost"

    # Check vhost config syntax
    nginx -t

    # Reload nginx configuration
    nginx -s reload
    echo "Site enabled. Check it out: http://$domain_name"
}

##########################################################################

print_help() {
cat << EOF
Create site dir and nginx virtual host.

Usage: site [-v | --version] [-h | --help] [--disabled] [--no-dir]
            [-e | --edit] [-y]  [-t | --template=<template>] <domain>

Options:
    --disabled                  don't enable virtual host.
    --no-dir                    don't create site directory.
    -e, --edit                  open vhost in default editor.
    -t, --template=<template>   use <template> for site.
    -y, --yes                   assume 'yes' in all dialogs.
    -h, --help                  print this message and exit.
    -v, --version               print version and exit.
EOF
exit 0
}

open_in_editor() {
    # $1 is file to open.

    get_selected_editor() {
        source $HOME/.selected_editor
        echo $SELECTED_EDITOR
    }

    # Detect default editor.
    if [ "$EDITOR" ]; then
        local e=$EDITOR
    elif [ -f $HOME/.selected_editor ]; then
        local e="$(get_selected_editor)"
    elif [ -f /usr/bin/select-editor ]; then
        select-editor
        local e="$(get_selected_editor)"
    else
        local e=/usr/bin/vi
    fi

    # Open file in editor.
    echo "Open $1 in editor ..."
    "$e" "$1"
}

yn_dialog() {
    local question="$1"  # Message prompt.
    local yes=0
    local no=1
    local pending=2

    [ "$assume_yes" = "1" ] && return "$yes"

    local answer=$pending

    while [ $answer -eq $pending ]
    do
        echo -en "$question [y/n] "
        read -r reply
        case "$reply" in
            y|Y|Yes|YES) answer=$yes;;
            n|N|No|NO)   answer=$no;;
            *) echo 'Please, answer y or n';;
        esac
    done

    return "$answer"
}

continue_dialog() {
    [ "$assume_yes" = "1" ] && return 0

    [ "$1" ] && echo -e "$1"  # Optional message prompt.
    echo 'Press RETURN to continue, or ^C to cancel.'
    read -e ignored
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

# Check root.
if [[ ! "$UID" == 0 ]]; then
    echo "$0: You must run this script as root." >&2
    exit 1
fi

# Check nginx.
if ! hash nginx 2>/dev/null
then
    echo "$0: nginx executable not found." >&2
    exit 1
fi

# Check args.
[[ "$@" ]] || print_help

while (( "$#" ))
do
    case "$1" in
        --disabled) disabled=1; shift;;
        --no-dir) no_dir=1; shift;;
        -e|--edit) edit=1; shift;;
        -y|--yes) assume_yes=1; shift;;
        -t|--template|--template=*)
            get_optarg "$1" "$2"
            template="$templates_dir/$arg";
            shift "$sft";;
        -h|--help) print_help;;
        -v|--version) echo "$0 $version"; exit 0;;
        -*) echo "$0: Bad option: $1" >&2; exit 1;;
        *)
            domain_name+=("$1")
            if [[ ${#domain_name[@]} > 1 ]]; then
                echo "$0: Too many arguments." >&2; exit 1
            fi
            shift;;
    esac
done

[ "$domain_name" ] || set_domain

check_vhost

if [ "$template" ]; then
    if [ ! -f "$template" ];then
        echo "$0: Template $template not found." >&2; exit 1
    fi
else
    select_template
fi

[ "$no_dir" ] || create_site_dir

create_vhost

[ "$edit" ] && open_in_editor "$vhost"

if [ ! "$disabled" ]; then
    continue_dialog "Nginx will be reloaded!"
    enable_vhost
fi
