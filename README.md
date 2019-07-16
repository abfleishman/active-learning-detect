# Setting up an Azure DSVM for Active Learning

This document will explain how to deploy an Azure DSVM and set up the environment for Active Learning.

## Deployment

Create an SSH Key on your local machine. The following will create a key in your ~/.ssh/act-learn-key location. Make sure you do not have  a passphase as authentication will not work in later steps using the python setup-script.py

```sh
$ ssh-keygen -f ~/.ssh/act-learn-key -t rsa -b 2048
```

We require that your SSH key be added to the SSH agent. To add your SSH key to the SSH agent use the **_ssh-add_** command

```sh
 eval `ssh-agent -s`
 ssh-add -k /c/Users/ConservationMetrics/.ssh/act-learn-key
```

Secondly edit the environment variables in the [dsvm_config.sh](config/dsvm_config.sh) script with your own values. For instance:

<pre>
RESOURCE_GROUP=<b>MyAzureResourceGroup</b>
# VM config
VM_SKU=Standard_NC6 #Make sure VM SKU is available in your resource group's region 
VM_IMAGE=microsoft-ads:linux-data-science-vm-ubuntu:linuxdsvmubuntu:latest
VM_DNS_NAME=<b>mytestdns</b>
VM_NAME=<b>myvmname</b>
VM_ADMIN_USER=<b>johndoe</b>
VM_SSH_KEY=~/.ssh/act-learn-key.pub
</pre>

Lastly execute the deploy_dsvm.sh with your edited config file as a parameter. Note that the Azure CLI is required. Install [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) if needed.
This should happen in git bash (on Windows) terminal on mac or shell on linux

```sh
$ sh deploy_dsvm.sh config/dsvm_config.sh
```

## Environment Setup 
We provide a module that will copy over a shell script to your DSVM and execute the shell script to setup an active learning environment.

To copy and execute the shell script on the DSVM use the following command
make sure cryptography is version 2.5 ofr more (this is python module
python -m pip uninstall cryptography
python -m pip install cryptography

#### on linux/unix run this
```sh
python setup-tensorflow.py --host cmi@52.175.208.196 -k /c/Users/ConservationMetrics/.ssh/act-learn-key -s setup-tensorflow.sh
```
Note that in the host argument **_admin_**@127.0.0.1 section is the DSVM Admin name and admin@**_127.0.0.1_** is the IP address of the DSVM.

#### on windows you must run it differently  
in git bash
```sh
# copy from local machine to ssh machine using scp
scp setup-tensorflow.sh cmi@52.175.208.196:setup-tensorflow.sh

#While you are at it copy the config you will use
scp ../../config_oikonos_mega.ini cmi@52.175.208.196:~/repos/models/research/active-learning-detect/config_oikonos_mega.ini

#then ssh in
ssh cmi@52.175.208.196

#fix the dos formated text file 
sudo apt install dos2unix
dos2unix setup-tensorflow.sh

# run the setup script
sh setup-tensorflow.sh

cd ~/repos/models/research/active-learning-detect/train

sh active_learning_initialize.sh ../config_oikonos_mega.ini
sh active_learning_train.sh ../config_oikonos_mega.ini

```


