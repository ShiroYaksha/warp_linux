#!/bin/bash
re_wireguard=false
verbose_flag=false
main_flag=false
wgcf_flag=false
wgcf_ver=2.1.4
files=none

is_offline() {
if $verbose_flag; then echo "Using google.com to check internet access"; fi

wget -q --spider http://google.com

if [ $? -eq 0 ]; then
    echo -e "\n>>-----[   Status: Online   ]"
    return 1
else
    echo -e "\n>>-----[   Status: Offline   ]"
    return 0
fi
}

start_WARP() {
if [ $# -gt 0 ]
then
    if $1
    then
         if $verbose_flag; then echo -e "value of re-run Wireguard flag is >> $re_wireguard" ; fi
        stop_WARP
        sleep 2
    fi
fi
echo -e "\n\t>> Starting...\n\n" 

if [ $files == "none" ]
then
    sudo wg-quick up wgcf-profile.conf 
else
    echo "files is $files"
    sudo wg-quick up $files
fi

re_wireguard=true
}

stop_WARP() {
echo -e "\n\t>> Stopping...\n\n" 

if [ $# -eq 0 ]
then
    if [ $files == "none" ]
    then
        sudo wg-quick down wgcf-profile.conf 
    else
        sudo wg-quick down $files
    fi

elif ! check_wg_profile
then
    echo "arg is $1"
    curr_conf=$(sudo wg | awk 'NR==1{print $2}')
    curr_conf="$curr_conf.conf"
    sudo wg-quick down $curr_conf
else
    echo -e "No WG Profile loaded"
fi
}


WARP_loop() {
while is_offline
do
    echo -e "\n\n>> Attempting to re-start WARP\n\n"
    start_WARP $re_wireguard
    sleep 4
done
}

check_wg_profile() {
wg_output_len=$(sudo wg | wc -c)
if [ $wg_output_len -eq 0 ]
then
    echo -e "No Wireguard config loaded...\t WARP profile will be loaded"
    return 0
else
    echo -e "Wireguard config Maybe loaded...\t use -v to verbose"
    if $verbose_flag; then echo -e "\n\nThis WG profile was found:\n\n"; sudo wg; fi
    return 1
fi
}

wgcf() {
echo -e "\nDownloading wgcf>> \n"
name=wgcf_"$wgcf_ver"_linux_amd64
wget -c -q --show-progress https://github.com/ViRb3/wgcf/releases/download/v$wgcf_ver/$name

echo -e "\n>> REGISTER WARP\n\n"
./$name register
echo -e "\n>> GENERATE WARP WireGuard Profile\n\n"
./$name generate

}

main() {
    if check_wg_profile
    then 
        echo -e "\n>> Starting warp..."
        start_WARP
        WARP_loop
    fi
}

if [ $# -gt 0 ]
then

    while getopts "hHSsf:vA" flag; do
            echo "Flag: ${flag}"
            case "${flag}" in
            
            h | H) echo -e "\nHelp >>" 
            echo -e "\n\t-H or -h: To print this Help.\n\t-S or -s: To Stop WARP" 
            echo -e "\t-v : verbose\n\t-A : Download wgcf and Generate WG profile"
            echo -e "\t-f : Specfic Profile\n"
            main_flag=false
            ;;
            
            S | s) echo -e "Stopping WARP" 
            stop_WARP "now"
            main_flag=false
            ;;
            
            
            f) files="${OPTARG}" 
            echo "custom :  $files"
            main_flag=true
            ;;
            
            v) verbose_flag=true
            ;;
            
            A) wgcf_flag=true
            main_flag=false
            break
            ;;
            
            *) echo "For help use -h or -H" ;;
            esac
    done
else
    main_flag=true
fi


if $main_flag
then
    main
fi

if $wgcf_flag
then
    wgcf
fi

echo -e "\n\n..done"
sleep 2
