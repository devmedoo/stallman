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
        temp_blacklist="/tmp/temp_blacklist.txt"
        pkg_del="/tmp/pkg_del.txt"
        installed_pkgs="/tmp/installed_pkgs.txt"
        proprietary_pkgs="/tmp/proprietary_pkgs.txt"

        pacman -Qqn > $installed_pkgs

        curl https://git.parabola.nu/blacklist.git/plain/blacklist.txt > $temp_blacklist

        sed -i '/branding/ d' $temp_blacklist
        egrep -o '^[a-z,A-Z,0-9,-]+' $temp_blacklist > $pkg_del

        comm --nocheck-order -1 -2 $pkg_del $installed_pkgs > $proprietary_pkgs

        echo -e "The following packages are absolutely proprietary and must be purged immediately: \n"
        cat $proprietary_pkgs 

        # todo: prompt the user for confirmation then delete the packages
        #       replace the deleted packages with free alternatives if available
        #
        # double check the blacklist bec some essential packages are reported as
        # proprietary such as pacman and base`;w
        ;;
    *)
        echo "Your distro is yet to be supported"
        ;;
esac
