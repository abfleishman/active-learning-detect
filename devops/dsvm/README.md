# Setting up an Azure DSVM for Training and Prediction

This document will explain how to deploy an Azure DSVM and set up the environment for Active Learning. Everything here should be run using GitBash which is an emulator for a unix based system allowing us to run the bash scripts (.sh) that our friends at Microsoft wrote.

## Check that you have Azure CLI installed and that you are logged in
Note that the Azure CLI is required for this work flow.  
The Azure CLI is a command line tool to interact with Azure.

Follow the instruction to install using the MSI installer, not the command line tool to install.
Install [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) if needed.

```
# Check that it is installed:
az.cmd --version

# Make sure you are logged in to the Azure CLI
az.cmd login

```

## Deployment
This will walk you though the steps needed to create a VM.  Before we do we must create an SSH key that we will feed to the VM to be able to access it later.

### Create a ssh key
Create an SSH Key on your local machine. The following will create a key in your ~/.ssh/act-learn-key location.
If you already have an SSH key that you want to use, you can skip this step.

```sh
$ ssh-keygen -f ~/.ssh/act-learn-key -t rsa -b 2048
```

Then start a instance of ssh-agent (key management software that runs in the background on your machine).
We require that your SSH key be added to the SSH agent. To add your SSH key to the SSH agent use the **_ssh-add_** command

```
eval "$(ssh-agent)"
ssh-add -k ~/.ssh/act-learn-key
```

### Set up the DSVM config file
Edit the environment variables in the [dsvm_config.sh](config/dsvm_config.sh) script with your own values, and save a copy with for the project you are working on in Dropbox or in the config folder.
For instance:

<pre>
RESOURCE_GROUP=<b>MyAzureResourceGroup</b>
LOCATION=westus2
VM_SKU=Standard_NC6_Promo # Must be a NC series machine for GPU computing. Make sure VM SKU is available in your resource group's region 
VM_IMAGE=microsoft-ads:linux-data-science-vm-ubuntu:linuxdsvmubuntu:latest
VM_NAME=<b>myvmname</b> # give it a unique VM name
VM_DNS_NAME=<b>mytestdns</b> # give it a unique DNS name
VM_ADMIN_USER=<b>cmi</b>
VM_SSH_KEY=/c/Users/ConservationMetrics/.ssh/act-learn-key.pub
</pre>

### Deploy and launch the VM
Lastly execute the deploy_dsvm.sh with your edited config file as a parameter. 

```
#change directory to the git repo you cloned
cd /D/CM,Inc/git_repos/active-learning-detect/devops/dsvm

# run the bash script (.sh) with your dsvm_config
sh deploy_dsvm.sh config/dsvm_config.sh

```

### Environment Setup 
We will need two GitBash consols for this section. One to ssh into the new VM and a second to use `scp` to send files to the VM from your local computer. `scp` is a commandline tool that sends files over ssh
#### For Windows
If on windows, run the setup-tensorflow.sh script on the VM over ssh.  

Make sure the EOL (end of line) format is unix (option in the edit menu of notpad++)

Note that in the host argument **_admin_**@127.0.0.1 section is the DSVM Admin name and admin@**_127.0.0.1_** is the IP address of the DSVM.

```
# this command will connect over ssh and run the `sh` (bash) the arguments after the "<" 
ssh -i "/c/Users/ConservationMetrics/.ssh2/act-learn-key.pub" cmi@52.247.196.244 "sh" < "/D/CM,Inc/git_repos/active-learning-detect/devops/dsvm/setup-tensorflow.sh"

```

Check the output for errors.  There are a few that happen and willnot effect things listed below:

in the section installing python packages:
> -ERROR: mxnet-model-server 1.0.1 requires model-archiver, which is not installed.

## Initialize a new project

### Edit the AL config file
You need to edit the AL config.ini file that you will be using for your new project. There is an example [here](https://github.com/abfleishman/active-learning-detect/blob/master/config.ini) and description of many of the parameters [here](https://github.com/abfleishman/active-learning-detect/blob/master/config_description.md) but there might be some required things missing from both (recent additions). 
### Send your AL config to the VM
In your second git bash consol, start an ssh agent, add the key, and then send your edited AL config to the VM (not the DSVM_config):
```
eval "$(ssh-agent)"
ssh-add -k ~/.ssh/act-learn-key-test

# scp copies a file to a remote computer into a folder (after the ":") on that computer 
scp "/D/CM,Inc/git_repos/ald/config_inception.ini" cmi@40.65.119.87:/home/cmi/repos/active-learning-detect
```

### initialize the project
Connect via SSH, initialize your active learning project by changing directory

here we are exicuting the command `sh ./active-learning-detect/train/active_learning_initialize.sh ...` on the remote machine.
```
ssh cmi@40.65.119.87

cd active-learning-detect/train

sh ./active_learning_initialize.sh ../config_inception.ini
```
#### NOT WORKING
The intention is that this would be able to run the script without being in an ssh session but it is not working.
```
ssh cmi@40.65.119.87 "cd ./repos/active-learning-detect/train&&sh ./active_learning_initialize.sh ../config_inception.ini"
```
After you do that you can switch to the R cmiimagetools workflow for labeling.  Once you have labeled a few images (100) then we can train a model


# Train model
ssh back into your VM and train a model.  remember to set you model training paramters in your config and if you change them localliy `scp` them back up tot he remote machine
```
ssh cmi@40.65.119.87
cd active-learning-detect/train
sh active_learning_train.sh ../config_usgs19_inception.ini

```

# Predict on new images without training
```
ssh cmi@40.65.119.87

cd active-learning-detect/train
sh active_learning_predict_no_train.sh ../config_usgs19_pred20191021.ini
```


# below here may not work so skip

# set up Remote Desktop
```
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
`az.cmd vm open-port --resource-group oikonos --name gpu --port 3389`

