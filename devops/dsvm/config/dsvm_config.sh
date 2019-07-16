#!/bin/bash

# System config 
RESOURCE_GROUP=oikonos

# VM config
VM_SKU=Standard_NC6_Promo
VM_IMAGE=microsoft-ads:linux-data-science-vm-ubuntu:linuxdsvmubuntu:latest
VM_DNS_NAME=gpudsn
VM_NAME=gpu
VM_ADMIN_USER=cmi
VM_SSH_KEY=/c/Users/ConservationMetrics/.ssh/act-learn-key.pub
