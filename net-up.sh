#!/bin/bash

set -ex

sudo ip tuntap add dev tap0 mode tap
sudo ip link add br0 type bridge

sudo ip link set tap0 master br0

sudo ip link set tap0 up
sudo ip link set br0 up

sudo ip addr add 192.168.100.1/24 dev br0

echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

sudo iptables -t nat -A POSTROUTING -o enp129s0f0np0 -j MASQUERADE
sudo iptables -A FORWARD -i br0 -o enp129s0f0np0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
