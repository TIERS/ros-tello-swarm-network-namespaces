# ros-tello-swarm (with network namespaces)

## EDIT

> :warning: **This repo is no longer under development.** The instructions for network namespaces are still mostly valid for connecting multiple Tello drones (the original Tello which cannot be connected to an external WiFi AP). Development has moved to [https://github.com/TIERS/uwb-tello-swam](https://github.com/TIERS/uwb-tello-swam) using Tello EDU drones and UWB-aided localization.

------

Create drone swarms using Tello drones with ROS (even with the basic Tello model). Formation control is possible with either UWB-based positioning or onboard odomtry (for simple scenarios).

If you are using the Tello EDU, then you can simply connect all drones to a single network.

If you are using the original Tello, then we will be setting network namespaces, so that you can connect to multiple Tellos from a single machine using the same amount of wireless adapters (e.g., we are using D-Link DWA-127).

## Installation

This instructions are for Ubuntu 18.04 with ROS Melodic already installed.

Clone this repo into your catkin_ws (the code below creates a new catkin workspace named tello_swarm_ws in your home folder):
```
mkdir -p  ~/tello_swarm_ws/src && cd ~/tello_swarm_ws/src
git clone --recursive https://github.com/TIERS/ros-tello-swarm.git
```

Then build the workspace. We recommend using `catkin build`. Install it if needed with
```
sudo apt install python-catkin-tools
```

then run
```
cd ~/tello_swarm_ws
catkin init
catkin build
```


## Setting up Network Namespaces

Before reading these instructions, make sure you have plugged in a USB Wi-Fi adapter, for example the D-Link DWA-127. You can find out the interface by running, for example
```
ip -c --human-readable a
```

In the case of the D-Link DWA-127, the interface name for us is `wlxf0b4d2aaf9XX` where the two last bytes change between modules.


In the following instructions, 
- Replace `$i` by numbers `0...N` where `N` is the number of drones you want to have in your swarm. 
- Replace `$j` with the number of the corresponding physical wireless card (potentially `phy0...phyN`). 
- Replace `$iface` with the name of the interface (e.g., `wlxf0b4d2aaf9ef`).
- Repalce `$tello` with the last sig digits, after the dash, of the `SSID` of the tello Wi-Fi AP (it will be something like `TELLO-XXXXXX`).

### Create namespaces and move interfaces

Create a new namespace
```
ip netns add ns$i
```

Add loopback interface
```
ip netns exec ns$i ip link set dev lo up
```

You can now ping it running a command from within that namespace with `ip netns exec ns$i ping 127.0.0.1`. You can also have a look at that namespace's iptables using `ip netns exec ns$i ip route show`, but it will be empty for now.

Now you need to assign a physical wireless card to that namespace.

First, using the name of the interface you got earlier, you can find the physical card number using 
```
iw dev $iface info 
```

To move physical cards, it is not enough to specify the name of the namespace, but instead we need the `pid` of a process running in that namespace. Here's a trick that does the job:
```
iw phy phy$j set netns "$(ip netns exec ns$i sh -c 'sleep 1 >&- & echo "$!"')" 
```

Now let's unblock the wireless device and connect it to the Tello. First get the id of the wireless device with
```
ip netns exec "ns$i" rfkill list all
```

Assuming your output is `$k`, unblock the device with
```
ip netns exec "ns1" rfkill unblock $k
```

and get the interface up
```
ip -n ns$i link set $iface up
```

you can also get the loopback interface up with `ip -n ns$i link set "lo" up`.

Now we cna finnaly connect to the Tello AP:
```
ip netns exec ns1 iw $iface connect -w "TELLO-$tello"
```

And now to get an ip you can either run a dhc client
```
ip netns exec ns$i dhclient "$iface"
```

or manually with `ip -n ns$i addr add "192.168.0.22/24" dev $iface` and `ip -n ns$i route add default via "192.168.0.1" dev $iface`

### Connect your new namespaces with the root namespace

Now we have an isolated interface in each of the namespaces. However, for ROS to be able to deliver messages between nodes running in different namespaces, we need to add a bridge. We will use a veth (Virtual Ethernet) device for each of the interfaces.

Create a new veth pair with
```
ip link add v-eth$i type veth peer name v-peer$i
```

And add the peer to the corresponding namespace (it is actually possible to do both in one command):
```
ip link set v-peer$i netns ns$i
```

Now let's set up some IP addresses
```
ip addr add 10.200.$i.1/24 dev v-eth$i
ip link set v-eth$i up
```

and the same for the peer
```
ip netns exec ns$i ip addr add 10.200.$i.2/24 dev v-peer$i
ip netns exec ns$i ip link set v-peer$i up
ip netns exec ns$i ip link set lo up
```
(the last instruction is not necessary if you already run it earlier).

### ROS

Basic setup for the root namespace running the ROS master:
```
export ROS_HOSTNAME=rosmaster
export ROS_MASTER_URI=http://rosmaster:11311
```

And then for each of the namespaces
```
export ROS_IP=10.200.$i.1
export ROS_MASTER_URI=http://10.200.$i.1:11311
```
