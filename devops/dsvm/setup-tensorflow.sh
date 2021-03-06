#!/bin/bash  
#
#This script automates the instructions from here:
#https://github.com/tensorflow/models/blob/master/research/object_detection/g3doc/installation.md
#
#
#Fail on first error
set -e
#Suppress expanding variables before printing.
set +x
set +v

#When executing on a DSVM over SSH some paths for pip, cp, make, etc may not be in the path,
export PATH=/anaconda/envs/py35/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/caffe/build/install/bin/:/usr/local/cuda/bin:/dsvm/tools/cntk/cntk/bin:/usr/local/cuda/bin:/dsvm/tools/cntk/cntk/bin:/dsvm/tools/spark/current/bin:/opt/mssql-tools/bin:/bin

echo -e '\n*******\tClone ALD \t*******\n'

git clone https://github.com/abfleishman/active-learning-detect repos/active-learning-detect

echo -e '\n*******\tClone Tensorflow Models\t*******\n'
git clone https://github.com/tensorflow/models.git repos/models
cd repos/models/ && git checkout fe748d4a4a1576b57c279014ac0ceb47344399c4 . && cd  ../..

echo -e '\n*******\tInstall Tensorflow package\t*******\n'
cd repos/models/ && pip install tensorflow-gpu==1.13.1

echo -e '\n*******\tInstall COCO API\t*******\n'
cd ~/
git clone https://github.com/cocodataset/cocoapi.git repos/cocoapi
cd repos/cocoapi/PythonAPI/
make 
cp -r pycocotools ~/repos/models/research/

echo -e '\n*******\tSetup Protocal Buffer\t******\n'
cd ~/
cd repos/models/research/
wget -O protobuf.zip https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip
unzip -o protobuf.zip
./bin/protoc object_detection/protos/*.proto --python_out=.

echo -e '\n*******\tSetup Python Path\t******\n'
export PYTHONPATH=$PYTHONPATH:`pwd`:`pwd`/slim

echo -e '\n*******\tRunning Object Detection Tests\t******\n'
python object_detection/builders/model_builder_test.py

# echo -e '\n*******\tClone Active Learning\t*******\n'
# pwd
# cd ~/
# cd repos/
# pwd
# git clone https://github.com/abfleishman/active-learning-detect

echo -e '\n*******\tInstalling Python Packages\t*******\n'
cd ~/
cd repos/active-learning-detect
pip install -r requirements.txt

# Update the config.ini file at repos/models/research/active-learning-detect
echo -e 'Objection dectection install validation complete'