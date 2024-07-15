#!/bin/bash

# Use the monitor from launch-qemu.sh
MONITOR_PATH=monitor
# devices="0000:e1:04.0"
devices=$*

usage() {
	echo "Usage: $0 0000:01:02.3 ..."
	exit 1
}

function connecttio()
{
	for dev in $* ; do
		PF="/sys/bus/pci/devices/$dev/tsm_dev"
		sudo bash -c 'echo 0 0 1 1 > $PF/tsm_sel_stream'
		sudo bash -c 'echo 1 > $PF/tsm_tc_mask'
		sudo bash -c 'echo 0 > $PF/tsm_cert_slot'
		sudo bash -c 'echo 2 > $PF/tsm_dev_connect'
		cat '$PF/tsm_dev_connect'
		cat '$PF/tsm_sel_stream'
	done
}

function vfiobind()
{
	for dev in $* ; do
		if ! ( readlink "/sys/bus/pci/devices/$dev/driver" | grep vfio-pci ) ; then
			sudo bash -c "echo $dev > /sys/bus/pci/devices/$dev/driver/unbind"
			sudo bash -c "echo vfio-pci > /sys/bus/pci/devices/$dev/driver_override"
			( set -x ; sudo bash -c "echo $dev > /sys/bus/pci/drivers/vfio-pci/bind" )
			sudo bash -c "echo '' > /sys/bus/pci/devices/$dev/driver_override"
		fi
	done
	sudo chown $USER:$USER /dev/vfio/* /dev/vfio/devices/vfio* /dev/iommu
}

function tdistat()
{
	for dev in $* ; do
		echo $dev: $(cat "/sys/bus/pci/devices/$dev/tsm_tdi_status")
	done
}

function qemuplugtio()
{
	i=0
	for dev in $* ; do
		# x-tio=true is the default in the QEMU's "tio" branch
		(set -x ; echo -e device_add vfio-pci,host=$dev,bus=r$i,id=v$i,iommufd=i0 | nc -q 0  -U $MONITOR_PATH )
		i=$(expr $i + 1 )
	done
	echo ""
}

if [ "$devices" == "" ] ; then
	usage
fi


sudo modprobe vfio_pci
sudo modprobe kvm_amd

connecttio $devices
vfiobind $devices
qemuplugtio $devices
tdistat $devices
