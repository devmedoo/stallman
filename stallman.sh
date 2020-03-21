#!/bin/bash

## TODO:
## - mention why package is bloated
## - suggesting replacements for absolutely proprietary packages

# RMS FACE #

rms="         @@@@@@ @        
       @@@@     @@       
      @@@@ =   =  @@     
     @@@ @ _   _   @@    
     @@@ @(0)|(0)  @@    
    @@@@   ~ | ~   @@    
    @@@ @  (o1o)    @@   
   @@@    #######    @   
   @@@   ##{+++}##   @@  
  @@@@@ ## ##### ## @@@@ 
  @@@@@#############@@@@ 
 @@@@@@@###########@@@@@@
@@@@@@@#############@@@@@
@@@@@@@### ## ### ###@@@@
 @ @  @              @  @
   @                    @"

# ECAF SMR #

red="\e[38;5;124m" # OUR RED COLOR CODE
reset="\e[0m" # NORMAL COLOR CODE

selectedpkg=1
frame=0
render=1
deletemsg=0
buffer=""


putspaces(){
    for i in $(seq 1 17); do buffer="$buffer "; done
}

putlaserspaces(){
    spaces=$((21-$frame))
    for i in $(seq 1 $spaces); do buffer="$buffer "; done
}

deletepkg(){
    render=0
    selectedpkgname=$(tail -n+$selectedpkg $proprietary_pkgs | head -n1)
    deletemsg=1
}

laserrms() {
    if (($frame == 0)); then
        buffer="\r\e[0K$buffer     @@@ @($redØ$reset)|($redØ$reset)  @@ ";
        ((frame++))
    elif (($frame < 21)); then
        buffer="\r\e[0K$buffer     @@@ @($redØ$reset)|($redØ$reset)  @@ ";
        for i in $(seq 1 $frame); do buffer="$buffer$red+$reset"; done
        ((frame++))
    elif (($frame == 21 )); then
        buffer="\r\e[0K$buffer     @@@ @($redØ$reset)|($redØ$reset)  @@ ";
        for i in $(seq 1 20); do buffer="$buffer$red+$reset"; done
        deletepkg
    fi
}

putpackages() {
    if (($outputpackages == 4)); then
        putlaserspaces
        line=$(($outputpackages-4+$selectedpkg))
        pkg=$(tail -n+$line $proprietary_pkgs | head -n1)
        buffer="\r\e[0K$buffer$pkg                          \n"
    elif (($outputpackages > 4)); then
        putspaces
        line=$(($outputpackages-4+$selectedpkg))
        pkg=$(tail -n+$line $proprietary_pkgs | head -n1)
        buffer="\r\e[0K$buffer$pkg                          \n"
    else
        buffer="\r\e[0K$buffer\n"
    fi
    ((outputpackages++))
}

angryrms() {
    buffer="\r\e[0K"
    while IFS= read -r line ; do
        putspaces
        if [[ $line == "     @@@ @(0)|(0)  @@    " ]]; then
            laserrms
            putpackages
            continue;
        fi
        buffer="\r\e[0K$buffer$line"; 
        putpackages
    done <<< "$rms"
    echo -e "$buffer"
}

prompt() {
    message="The following packages are absolutely proprietary and must be purged immediately!"
    tput cuu 44 && tput el && tput rc
    echo -e "$message"
    angryrms
    printf "$tailmsg"
    if [ $deletemsg -eq 1 ]; then
        printf "Delete bloated package $selectedpkgname ? [y/N]:                              "
        read -n1 rmrfroot
         if [ "$rmrfroot" != "${rmrfroot#[Yy]}" ] ;then
            case $distro in
                arch)
                    echo ""
                    sudo pacman -Rs $selectedpkgname
                    ;;
                *)
                    echo -n "How the hell did you get here?" # unsupported distro, how the hell did they pass the first check in get_package_blacklist
                    ;;
            esac
        fi
        ((selectedpkg++))
        frame=0
        deletemsg=0
        render=1
    else
        printf "                                                           "
    fi
}

renderprompt() {
    if [ $render -eq 1 ]; then
        tput civis      -- invisible
        outputpackages=0
        prompt
        sleep 0.00001
    else
        tput cnorm   -- normal
    fi
    
    renderprompt
}

get_package_blacklist() {
    case $distro in
        arch)
            temp_blacklist="/tmp/temp_blacklist.txt"
            pkg_del="/tmp/pkg_del.txt"
            installed_pkgs="/tmp/installed_pkgs.txt"
            proprietary_pkgs="/tmp/proprietary_pkgs.txt"

            pacman -Qqn > $installed_pkgs

            curl -s https://git.parabola.nu/blacklist.git/plain/blacklist.txt > $temp_blacklist

            sed -i '/branding/ d' $temp_blacklist
            egrep -o '^[a-z,A-Z,0-9,-]+' $temp_blacklist > $pkg_del

            comm --nocheck-order -1 -2 $pkg_del $installed_pkgs > $proprietary_pkgs

            #echo -e "The following packages are absolutely proprietary and must be purged immediately: \n"
            renderprompt

            ;;
        *)
            echo "Your distro is yet to be supported"
            ;;
    esac
}


main() {
    tput sc
    if [ -f /etc/os-release ]; then
        if ( grep "ID_LIKE" /etc/os-release >/dev/null ); then
            distro="$(grep "^ID_LIKE" /etc/os-release | cut -c 9-)"
        elif ( grep "ID" /etc/os-release >/dev/null ); then
            distro="$(grep "^ID" /etc/os-release | cut -c 4-)"
        else
            echo "Your operating system is not supported"
            exit 1
        fi
    else
        echo "Your operating system is not supported"
        exit 1
    fi

    echo -e "$rms"

    get_package_blacklist

}

main