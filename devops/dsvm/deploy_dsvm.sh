#!/bin/bash

# Within the configuration file, there is a need for an SSH key.  To generate an SSH
# key on Linux, one uses the ssk-keygen command.  The format is:
#
# ssh-keygen -f ~/.ssh/act-learn-key -t rsa -b 2048

# Check if any of the args are empty
if [ -z "$1" ]; then
    echo "Usage: 'sh $0 (configuration file)'"
    exit 1
fi

# Does the configuration exist?
if [ ! -e "$1" ]; then
    echo "Unable to find configuration file -- $1"
    exit 1
fi

# Read in the configuration
. $1

# Check and see if Azure CLI is present
az.cmd --version > /dev/null
if [ "$?" -ne "0" ]; then
    echo "Unable to find azure CLI"
    exit 1
fi

# Is the ssh key present?
if [ ! -e "$VM_SSH_KEY" ]; then
    echo "SSH key file does not exist -- $VM_SSH_KEY"
    exit 1
fi

# Does the resource group exist
RESOURCE_GROUP_PRESENT=`az.cmd group exists --name $RESOURCE_GROUP`
echo "$RESOURCE_GROUP exists? $RESOURCE_GROUP_PRESENT"
if [ "$RESOURCE_GROUP_PRESENT" == "false" ]; then
    echo "Resource group does not exist -- $RESOURCE_GROUP creating..."
	az.cmd group create \
		--name $RESOURCE_GROUP \
		--location $LOCATION
fi
echo "Creating VM $VM_NAME in $RESOURCE_GROUP in the region $LOCATION" 
az.cmd vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --admin-username $VM_ADMIN_USER \
    --public-ip-address-dns-name $VM_DNS_NAME \
    --image $VM_IMAGE \
    --size $VM_SKU \
    --ssh-key-value $VM_SSH_KEY \
	--location $LOCATION
if [ "$?" -ne "0" ]; then
    echo "Unable to provision DSVM"
    exit 1
fi
