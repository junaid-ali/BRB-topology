#!/bin/bash

# This script will create two VMs connected to two different networks
# Both networks will be connected to a router. An external network will serve
# as default gateway for this router, enabling VMs to have external connectivity.

set -e

read -p "Enter gateway node hostname: " gw_hostname
read -p "Enter gateway node interface: " gw_interface
read -p "Enter external network CIDR: " ext_cidr
neutron net-create net1
neutron subnet-create net1 10.0.0.0/24 --name sub_net1
neutron net-create net2
neutron subnet-create net2 11.0.1.0/24 --name sub_net2
neutron router-create router1
neutron router-interface-add router1 sub_net1
neutron router-interface-add router1 sub_net2
neutron physical-attachment-point-create pap1 --interface hostname=$gw_hostname,interface_name=$gw_interface --hash_mode=L2 --lacp false
neutron net-create ext_net --router:external --provider:network_type flat --provider:physical_network pap1
neutron subnet-create ext_net $ext_cidr --name sub_ext --enable_dhcp False --gateway_ip $(echo $ext_cidr | cut -d'/' -f1 | sed -e 's/0$//')1
neutron router-gateway-set router1 ext_net
glance image-create --name Cirros --disk-format=qcow2 --container-format=bare --is-public=True --copy-from "http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img"

echo '     *********************************************'
echo '     |         Sleeping for 7 seconds            |'
echo '     *********************************************'
sleep 7

nova boot --image Cirros --flavor 1 --nic net-id=$(neutron net-list | grep net1 |  awk '{print $2}' | grep -v id) vm1
sleep 3
nova boot --image Cirros --flavor 1 --nic net-id=$(neutron net-list | grep net2 |  awk '{print $2}' | grep -v id) vm2
clear
echo '     *********************************************'
echo '     |                SUMMARY                    |'
echo '     |********************************************'
echo '     |      net1          |    10.0.0.0/24       |'
echo '     |      net2          |    11.0.1.0/24       |'
echo '     |      ext_net       |    '$ext_cidr'    |'
echo '     |      router1       |    net1,net2,ext_net |'
echo '     |      Cirros        |    Active            |'
echo '     |      pap1          |    ext_net           |'
echo '     |      vm1           |    net1              |'
echo '     |      vm2           |    net2              |'
echo '     *********************************************'
