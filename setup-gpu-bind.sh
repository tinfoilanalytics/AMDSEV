#!/bin/bash

LSPCI_OUT=$(lspci -d 10de: -nn)

SLOT_ID=$(echo $LSPCI_OUT | cut -d " " -f 1)
DEVICE_ID=$(echo $LSPCI_OUT | cut -d "]" -f 3 | cut -d ":" -f 2)

echo "Found GPU in slot $SLOT_ID device ID $DEVICE_ID"

sudo modprobe vfio
sudo modprobe vfio_pci

echo "10de $DEVICE_ID" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id
