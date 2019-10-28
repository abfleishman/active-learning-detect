# Setting up an Azure DSVM for Training and Prediction

This document will explain how to deploy an Azure DSVM and set up the environment for Active Learning.

## Deployment

Create an SSH Key on your local machine. The following will create a key in your ~/.ssh/act-learn-key location.
If you already have an SSH key that you want to use, you can skip this step.

This should be done in GitBash

```sh
$ ssh-keygen -f ~/.ssh/act-learn-key-test -t rsa -b 2048
```

Secondly edit the environment variables in the [dsvm_config.sh](config/dsvm_config.sh) script with your own values, and save a copy with for the project you are working on.
For instance:

<pre>
RESOURCE_GROUP=<b>MyAzureResourceGroup</b>
# VM config
VM_SKU=Standard_NC6_Promo #Make sure VM SKU is available in your resource group's region 
VM_IMAGE=microsoft-ads:linux-data-science-vm-ubuntu:linuxdsvmubuntu:latest
VM_DNS_NAME=<b>mytestdns</b>
VM_NAME=<b>myvmname</b>
VM_ADMIN_USER=<b>johndoe</b>
VM_SSH_KEY=~/.ssh/act-learn-key.pub
</pre>

Lastly execute the deploy_dsvm.sh with your edited config file as a parameter. Note that the Azure CLI is required.
Install [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) if needed.

```

cd /D/CM,Inc/git_repos/active-learning-detect/devops/dsvm
az login
sh deploy_dsvm.sh config/dsvm_config.sh

```

## Environment Setup 
We provide a module that will copy over a shell script to your DSVM and execute the shell script to setup an active learning environment.

We require that your SSH key be added to the SSH agent. To add your SSH key to the SSH agent use the **_ssh-add_** command

```
eval "$(ssh-agent)"
ssh-add -k ~/.ssh/act-learn-key-test
```

If you are working on a Mac or Linux OS:  Use this python script to copy and execute the shell script on the DSVM using the following command

```
python setup-tensorflow.py --host cmi@52.191.129.248 -k ~/.ssh/act-learn-key -s setup-tensorflow.sh
```

Note that in the host argument **_admin_**@127.0.0.1 section is the DSVM Admin name and admin@**_127.0.0.1_** is the IP address of the DSVM.

If on windows, use scp to copy the script to the dsvm and then ssh in and exicute the script.  make sure the EOL (end of line) format is unix (option in the edit menu of notpad++)

```
scp "/D/CM,Inc/git_repos/ald2/ald/devops/dsvm/setup-tensorflow.sh"  cmi@51.141.161.147:/home/cmi
```
Once you have run that you can ssh into the machine and run the script we copied over:
```
ssh cmi@51.141.161.147
sh setup-tensorflow.sh
```

Open a new git bash consol and start an ssh agent and then send your edited AL config to the VM:
```
eval "$(ssh-agent)"
ssh-add -k ~/.ssh/act-learn-key-test
# scp "/D/CM,Inc/Dropbox (CMI)/CMI_Team/Analysis/2019/USGS_AerialImage_2019/configs/config_usgs19_pred20191021.ini" cmi@51.141.161.147:/home/cmi/active-learning-detect
scp "/D/CM,Inc/git_repos/ald/config_inception.ini" cmi@51.141.161.147:/home/cmi/active-learning-detect
```

Back in your SSH session, initialize your active learning project by changing directory

```
cd active-learning-detect/train
sh active_learning_initialize.sh ../config_inception.ini
```
After you do that you can switch to the R cmiimagetools workflow for labeling.  Once you have labeled a few images (100) then we can train a model

# Train model
ssh back into your VM 
```
ssh cmi@51.141.161.147
cd active-learning-detect/train
sh active_learning_train.sh ../config_usgs19_inception.ini

```

# Predict on new images without training
```
cd active-learning-detect/train
sh active_learning_predict_no_train.sh ../config_usgs19_pred20191021.ini
```


# below here may not work so skip

# set up Remote Desktop
```sh
sudo apt-get update
sudo apt-get install xfce4

sudo apt-get install xrdp=0.6.1-2
sudo systemctl enable xrdp

echo xfce4-session >~/.xsession

sudo service xrdp restart
sudo passwd cmi
sudo service xrdp restart
```
### not on VM ###
`az vm open-port --resource-group oikonos --name gpu --port 3389`

