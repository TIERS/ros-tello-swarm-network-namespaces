#!/bin/bash

declare -a iface_names=("wlxf0b4d2aaf9ef" "wlxf0b4d2aaf9ca" "wlxf0b4d2aaf9ee" "wlxf0b4d2aaf9ec")

declare -a tello_wifis=("TELLO-5C28B9" "TELLO-5C28D2" "TELLO-5C28D8" "TELLO-5C28AA")

while /bin/true; do

	for i in {0..3}
	do
		
		ip netns exec ns$((i+1)) ifconfig | grep -q '192.168.10.2' && echo "[NS$((i+1))] IP: 192.168.10.2"
		ip netns exec ns$((i+1)) ifconfig | grep -q '192.168.10.2' || echo "[NS$((i+1))] IP:"

		if ip netns exec ns$((i+1)) iw "${iface_names[$i]}" connect -w "${tello_wifis[$i]}" \
			| grep -q 'connected\|already';\
		then

			echo "[NS$((i+1))] Connected! (dev: ${iface_names[$i]},  WiFi: ${tello_wifis[$i]}  ---  READY TO ROLL"

		else

			echo "[NS$((i+1))] Disconnected from ${tello_wifis[$i]}"

		fi

	done
	sleep 1
	printf "\n\n"


done
