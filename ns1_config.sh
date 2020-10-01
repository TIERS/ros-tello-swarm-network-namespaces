#!/bin/bash

echo "Configuring network namespace ns1 for Tello/ROS"

# ROS Networking
export ROS_IP=10.200.1.2
export ROS_MASTER_URI=http://10.200.1.1:11311
export ROS_NAMESPACE=ns1

echo " --> ROS_IP=$ROS_IP"
echo " --> ROS_MASTER_URI=$ROS_MASTER_URI"
echo " --> ROS_NAMESPACE=$ROS_NAMESPACE"

source /opt/ros/melodic/setup.bash
source /home/bot/tello_ws/devel/setup.bash