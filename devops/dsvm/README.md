# Setting up an Azure DSVM for Active Learning

This document will explain how to deploy an Azure DSVM and set up the environment for Active Learning.

## Deployment

Create an SSH Key on your local machine. The following will create a key in your ~/.ssh/act-learn-key location.

```sh
$ ssh-keygen -f ~/.ssh/act-learn-key -t rsa -b 2048
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

```sh
cd /D/CM,Inc/git_repos/ald2/ald/devops/dsvm
sh deploy_dsvm.sh config/ic_dsvm_config.sh
```

## Environment Setup 
We provide a module that will copy over a shell script to your DSVM and execute the shell script to setup an active learning environment.

We require that your SSH key be added to the SSH agent. To add your SSH key to the SSH agent use the **_ssh-add_** command

```sh
eval "$(ssh-agent)"
ssh-add -k ~/.ssh/act-learn-key
```

To copy and execute the shell script on the DSVM use the following command

```sh
$ python setup-tensorflow.py --host cmi@52.191.129.248 -k ~/.ssh/act-learn-key -s setup-tensorflow.sh
```

Note that in the host argument **_admin_**@127.0.0.1 section is the DSVM Admin name and admin@**_127.0.0.1_** is the IP address of the DSVM.

If on windows, use scp to copy the script to the dsvm and then ssh in and exicute the script.  make sure the EOL (end of line) format is unix (option in the edit menu of notpad++

```
scp "/D/CM,Inc/git_repos/ald2/ald/devops/dsvm/setup-tensorflow.sh"  cmi@52.191.129.248:/home/cmi

ssh cmi@52.191.129.248
sh setup-tensorflow.sh
git clone https://github.com/olgaliak/active-learning-detect.git
scp "/D/CM,Inc/Dropbox (CMI)/CMI_Team/Analysis/2019/IC_AI4Earth_2019/configs/config_ic-AI4Earth.ini" cmi@52.191.129.248:/home/cmi/repos/active-learning-detect
# Setup RDP
sudo apt-get update
sudo apt-get install xrdp 
sudo apt-get install xfce4
sudo apt-get install xfce4-terminal
sudo apt-get install gnome-icon-theme-full tango-icon-theme
sudo sed -i.bak '/fi/a #xrdp multiple users configuration \n xfce-session \n' /etc/xrdp/startwm.sh
sudo ufw allow 3389/tcp
sudo /etc/init.d/xrdp restart

# load config
scp "/D/CM,Inc/Dropbox (CMI)/CMI_Team/Analysis/2019/PointBlue_Penguins_2019/configs/config_pointblue.ini" cmi@52.191.129.248:/home/cmi/active-learning-detect
cd active-learning-detect/train/
