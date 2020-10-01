
# Create namespace
ip netns add ns1
ip netns add ns2
ip netns add ns3
ip netns add ns4

# Add loopback iface
ip netns exec ns1 ip link set dev lo up # alternative: ip netns exec ns1 ifconfig lo up
ip netns exec ns2 ip link set dev lo up
ip netns exec ns3 ip link set dev lo up
ip netns exec ns4 ip link set dev lo up

# Check it's ok
ip netns exec ns1 ping 127.0.0.1
ip netns exec ns2 ping 127.0.0.1
ip netns exec ns3 ping 127.0.0.1
ip netns exec ns4 ping 127.0.0.1

# To see the routing table (will be empty for now...)
ip netns exec ns1 ip route show

# Add physical card to it
iw phy phy0 set netns "$(ip netns exec ns1 sh -c 'sleep 1 >&- & echo "$!"')" 
iw phy phy1 set netns "$(ip netns exec ns2 sh -c 'sleep 1 >&- & echo "$!"')" 
iw phy phy2 set netns "$(ip netns exec ns3 sh -c 'sleep 1 >&- & echo "$!"')" 
iw phy phy3 set netns "$(ip netns exec ns4 sh -c 'sleep 1 >&- & echo "$!"')" 

# To get the phy address use:
iw dev "wlxf0b4d2aaf9ef" info 
iw dev "wlxf0b4d2aaf9ca" info
iw dev "wlxf0b4d2aaf9ee" info
iw dev "wlxf0b4d2aaf9ec" info

# To move it back to the root namespace
# ip netns exec ns1 iw phy phy0 set netns 1

# Unblock the wireless 
ip netns exec "ns1" rfkill list all
ip netns exec "ns2" rfkill list all
ip netns exec "ns3" rfkill list all
ip netns exec "ns4" rfkill list all

ip netns exec "ns1" rfkill unblock 1 # Get the number from previous command
ip netns exec "ns2" rfkill unblock 1
ip netns exec "ns3" rfkill unblock 2
ip netns exec "ns4" rfkill unblock 1

# Interface up (also loopback up)
ip -n ns1 link set "wlxf0b4d2aaf9ef" up
ip -n ns2 link set "wlxf0b4d2aaf9ca" up
ip -n ns3 link set "wlxf0b4d2aaf9ee" up
ip -n ns4 link set "wlxf0b4d2aaf9ec" up

ip -n ns1 link set "lo" up
ip -n ns2 link set "lo" up
ip -n ns3 link set "lo" up
ip -n ns4 link set "lo" up

# Connect to Tello Wi-Fi
ip netns exec ns1 iw "wlxf0b4d2aaf9ef" connect -w "TELLO-5C28B9"  # Not putting here what to do if there's a password....
ip netns exec ns2 iw "wlxf0b4d2aaf9ca" connect -w "TELLO-5C28D2" 
ip netns exec ns3 iw "wlxf0b4d2aaf9ee" connect -w "TELLO-5C28D8" 
ip netns exec ns4 iw "wlxf0b4d2aaf9ec" connect -w "TELLO-5C28AA"  

# DHCP client
ip netns exec ns1 dhclient "wlxf0b4d2aaf9ef"
ip netns exec ns2 dhclient "wlxf0b4d2aaf9ca"
ip netns exec ns3 dhclient "wlxf0b4d2aaf9ee"
ip netns exec ns4 dhclient "wlxf0b4d2aaf9ec"

# Alternatively manually
# -- ip -n ns1 addr add "192.168.0.22/24" dev "wlan0"
# and then
# -- ip -n ns1 route add default via "192.168.0.1" dev "wlan0"

# Set Google DNS server (not needed for Tello Wi-Fi...)
# -- mkdir -p "/etc/netns/ns1"
# -- echo "nameserver 8.8.8.8" > /etc/netns/ns1/resolv.conf

# Shutting down...
# -- ip netns pids "ns1" | xargs kill -15
# -- sleep 12
# -- ip netns pids "ns1" | xargs kill -9

# Delete it (?)
# -- ip netns delete ns1





# Create veth link.
ip link add v-eth1 type veth peer name v-peer1
ip link add v-eth2 type veth peer name v-peer2
ip link add v-eth3 type veth peer name v-peer3
ip link add v-eth4 type veth peer name v-peer4

# Add peer-1 to NS.
ip link set v-peer1 netns ns1
ip link set v-peer2 netns ns2
ip link set v-peer3 netns ns3
ip link set v-peer4 netns ns4

# Setup IP address of v-eth1.
ip addr add 10.200.1.1/24 dev v-eth1
ip link set v-eth1 up

ip addr add 10.200.2.1/24 dev v-eth2
ip link set v-eth2 up

ip addr add 10.200.3.1/24 dev v-eth3
ip link set v-eth3 up

ip addr add 10.200.4.1/24 dev v-eth4
ip link set v-eth4 up


# Setup IP address of v-peer1.
ip netns exec ns1 ip addr add 10.200.1.2/24 dev v-peer1
ip netns exec ns1 ip link set v-peer1 up
ip netns exec ns1 ip link set lo up


ip netns exec ns2 ip addr add 10.200.2.2/24 dev v-peer2
ip netns exec ns2 ip link set v-peer2 up
ip netns exec ns2 ip link set lo up


ip netns exec ns3 ip addr add 10.200.3.2/24 dev v-peer3
ip netns exec ns3 ip link set v-peer3 up
ip netns exec ns3 ip link set lo up


ip netns exec ns4 ip addr add 10.200.4.2/24 dev v-peer4
ip netns exec ns4 ip link set v-peer4 up
ip netns exec ns4 ip link set lo up


# Setup the following int he root namespace where roscore will run
export ROS_HOSTNAME=10.200.1.1
export ROS_IP=10.200.1.1
export ROS_MASTER_URI=http://10.200.1.1:11311

# Setup the following in each of the namespaces where ros nodes will run
export ROS_IP=10.200.2.1
export ROS_MASTER_URI=http://10.200.2.1:11311