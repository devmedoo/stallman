#!/bin/sh

if [ -f /etc/os-release ]; then
    if ( grep "ID_LIKE" /etc/os-release >/dev/null ); then
        distro="$(grep "^ID_LIKE" /etc/os-release | cut -c 9-)"
    elif ( grep "ID" /etc/os-release >/dev/null ); then
        distro="$(grep "^ID" /etc/os-release | cut -c 4-)"
    else
        echo "Your distro is not supported"
        exit 1
    fi
else
    echo "Your distro is not supported"
    exit 1
fi

case $distro in
    arch)
        # todo: curl the blacklist from parabola's site
        #       then diff it with the list of packages
        #       and prompt to remove
        echo $distro
        ;;
    *)
        echo "Your distro is yet to be supported"
        ;;
esac
