#!/bin/bash
re_wireguard=false
verbose_flag=false

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
sudo wg-quick up wgcf-profile.conf 
re_wireguard=true
}

stop_WARP() {
echo -e "\n\t>> Stopping...\n\n" 
sudo wg-quick down wgcf-profile.conf 
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

    while getopts "SshHcv" flag; do
            echo "i: ${flag}"
            case "${flag}" in
            S | s) echo -e "Stopping WARP" 
            stop_WARP
            exit 0
            ;;
            
            h | H) echo "Help" 
            echo -e "\n\t-H or -h: To print this Help.\n\t-S or -s: To Stop WARP" 
            ;;
            
            c) files="${OPTARG}" ;;
            
            v) verbose_flag=true 
            ;;
            
            *) echo "For help use -h or -H" ;;
            esac
    done
fi

main
echo -e "\n\n..done"
sleep 2
