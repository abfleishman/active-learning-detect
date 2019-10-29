#!/bin/bash

# System config 
RESOURCE_GROUP=cmitestnowgroup
LOCATION=westus2

# VM config
VM_SKU=Standard_NC6_Promo
VM_IMAGE=microsoft-ads:linux-data-science-vm-ubuntu:linuxdsvmubuntu:latest
VM_DNS_NAME=gputestnowdsn
VM_NAME=gputestnow
VM_ADMIN_USER=cmi
VM_SSH_KEY=/c/Users/ConservationMetrics/.ssh/act-learn-key.pub
