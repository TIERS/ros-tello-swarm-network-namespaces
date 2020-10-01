#!/bin/bash

declare -a iface_names=("wlxf0b4d2aaf9ef" "wlxf0b4d2aaf9ca" "wlxf0b4d2aaf9ee" "wlxf0b4d2aaf9ec")
declare -a tello_wifis=("TELLO-5C28B9" "TELLO-5C28D2" "TELLO-5C28D8" "TELLO-5C28AA")

while /bin/true; do

	for i in {0..3}
		j=i+1
		ip netns exec ns$j iw "${iface_names[$i]}" connect -w "${iface_names[$i]}" | grep -q 'connected\|already' && ip netns exec ns$j dhclient "${iface_names[$i]}" &> /dev/null
		sleep 1
