# ros-tello-swarm

Create drone swarms using Tello drones with ROS (even with the basic Tello model). Formation control is possible with either UWB-based positioning or onboard odomtry (for simple scenarios).

If you are using the Tello EDU, then you can simply connect all drones to a single network.

If you are using the original Tello, then we will be setting network namespaces, so that you can connect to multiple Tellos from a single machine using the same amount of wireless adapters (e.g., we are using D-Link DWA-127).

## Setup Network Namespaces

Before reading these instructions, make sure you have plugged in


In the following instructions, replace `$i` by numbers `0...N` where `N` is the number of drones you want to have in your swarm. Replace $j with the number of the corresponding physical wireless card (potentially `phy0...phyN`).

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
First,

To move physical cards, it is not enough to specify the name of the namespace, but instead we need the `pid` of a process running in that namespace. Here's a trick that does the job:
```
iw phy phy$j set netns "$(ip netns exec ns$i sh -c 'sleep 1 >&- & echo "$!"')" 
```
where you should

### ROS