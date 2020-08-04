# Active learning + object detection
Labeling images for object detection is commonly required task to get started with Computer Vision related project.
Good news that you do not have to label all images  (draw bounding boxes) from scratch --- the goal of this project is to add (semi)automation to the process. 
Please refer to this blog post that describes Active Learning and semi-automated flow: 
  [Active Learning for Object Detection in Partnership with Conservation Metrics](https://www.microsoft.com/developerblog/2018/11/06/active-learning-for-object-detection/)
We will use Transfer Learning and Active Learning as core Machine Learning  components of the pipeline.
 -- Transfer Learning: use powerful pre-trained on big dataset (COCO) model as a starting point for fine-tuning foe needed classes.
 -- Active Learning: human annotator labels small set of images (set1), trains Object Detection Model  (model1) on this set1 and then uses model1 to predict bounding boxes on images (thus pre-labeling those). Human annotator reviews mode1's predictions where the model was less confident -- and thus comes up with new set of images -- set2. Next phase will be to train more powerful model2 on bigger train set that includes set1 and set2 and use model2 prediction results as draft of labeled set3…
The plan is to have 2 versions of pipeline set-up.

# Semi-automated pipeline

![Flow](images/semi_automated.png)  

This one (ideally) includes minimum setup. The core components here are: 
1) Azure Blob Storage with images to be labeled.
It will also be used to save "progress" logs of labeling activities
2) "Tagger" machine(s) 
This is computer(s) that human annotator(s) is using as environment for labeling portion of images -- for example [VOTT](https://github.com/Microsoft/VoTT).  
Here example of labeling flow in VOTT: I've labeled wood "knots" (round shapes) and "defect" (pretty much  non-round shaped type of defect):

![Labeling](images/VOTT_knot_defect.PNG)


3) Model re-training machine (or service)
This is environment were Object Detection model is retrained with growing train set as well as does predictions of bounding boxes on unlabeled images.
There is config.ini that needs to be updated with details like blob storage connection  and model retraining configuration. 

# Automated pipeline
More details TBD.  
Basically the idea is to kick off Active Learning cycle with model retaining as soon as human annotator revises new set of images.

# Notes before we get started 
- The steps below refer to updating config.ini. You can find detailed description of config [here](config_description.md) 
- Got several thousands of images (or much more) and not sure if random sampling will be helpful to get rolling with labeling data? 
Take a look at [Guide to "initialization" predictions](init_pred_desription.md).

# How to run semi-automated pipeline
The flow below assumes the following: 
1) We use Tensorflow Object Detection API (Faster RCNN with Resnet 50 as default option)  to fine tune object detection. 
2) Tensorflow Object Detection API is setup on Linux box (Azure DSVM is an option) that you can ssh to. See docs for Tensorflow Object Detection API regarding its general config.
3) Data(images) is in Azure blob storage
4) Human annotators use [VOTT](https://github.com/Microsoft/VoTT)  to label\revise images.  To support another tagging tool it's output (bounding boxes) need to be converted to csv form -- pull requests are welcomed!

Here is general flow has 2 steps:
1) Environments setup
2) Active Learning cycle: labeling data and running scripts to update model and feed back results for human annotator to review.  
The whole flow is currently automated with **4 scrips** user needs to run.


### General  prep
1) Provision Azure Blob storage. Create 2 containers: _"activelearningimages"_ and _"activelearninglabels"_
2) Upload unzipped folder with images to  _"activelearningimages"_ container.


### On Linux box aka Model (re)training env
Run the devops/dsvm/deploy_dsvm.sh script to create a VM for this process. follow the instructions [here]()

### Tagger machine(s) (could be same as Linux box or separate boxes\vms)
1) Have Python 3.6+ up and running 
TODO: add section for installing python 
If you do not have python 3.6+ download [anaconda python](https://www.anaconda.com/distribution/#download-section) 
```
python --version

python -m pip install azure.storage.blob
```
3) Clone this repo, copy  updated config.ini from Model re-training box (as it has Azure Blob Storage and other generic info already).
4) Update  _config.ini_ values for _# Tagger Machine_ section:    This is a temporary directory, and the process will delete all the 
   files every time you label so do not use an existing dir that you care about
        `tagging_location=D:\temp\NewTag`

### On Linux box aka Model (re)training env
Run bash script to Init pipeline  
`~/repos/models/research/active-learning-detect/train$ . ./active_learning_initialize.sh  ../config.ini`
This step will:
- Download all images to the box.
- Create totag_xyz.csv on the blob storage ( "activelearninglabels" container by default).  
This is the snapshot of images file names that need tagging (labeling).  As human annotators make progress on labeling data the list will get smaller and smaller.

### Label Now model can be trained.

### Model(re)training on Linux box
Before your first time running the model, and at any later time if you would like to repartition the test set, run:

`~/repos/models/research/active-learning-detect/train$ . ./repartition_test_set_script.sh  ../config.ini`

This script will take all the tagged data and split some of it into a test set, which will not be trained/validated on and will then be use by evaluation code to return mAP values.

Run bash script:  
`~/repos/models/research/active-learning-detect/train$ . ./active_learning_train.sh  ../config.ini`

This script will kick of training based on available labeled data.  

Model will evaluated on test set and perf numbers will be saved in blob storage (performance.csv).

Latest totag.csv will have predictions for all available images made of the newly trained model -- bounding box locations that could be used by human annotator as a starter.

### Reviewing of pre-labeled results (on Tagger machine)
Human annotator(s) deletes any leftovers from previous predictions (csv files in active-learning-detect\tag, image dirs) and runs goes again sequence of:
1) Downloading next batch of pre-labeled images for review (`active-learning-detect\tag\download_vott_json.py`)
2) Going through the pre-labeled images with [VOTT](https://github.com/Microsoft/VoTT)  and fixing bounding boxes when needed.
3) Pushing back new set of labeled images to storage (`active-learning-detect\tag\upload_vott_json.py`) 

Training cycle can now be repeated on bigger training set and dataset with higher quality of pre-labeled bounding boxes could be obtained. 

# Running prediciton on a new batch of data (existing model)

Send the config to the remote machine (make sure it is updated with the model that you want to use).
```
scp "config_usgs19_pred20191021.ini" cmi@13.77.159.88:/home/cmi/active-learning-detect
```

SSH into the machine

```
cmi@13.77.159.88
```

Remove the old training directory to avoid running prediction on the last batch of images you uploaded.

```
rm -rd data
```

change directory to "train" 

```
cd active-learning-detect/train
```

Run the prediction script with the config that you just uploaded

active_learning_predict_no_train.sh uses the info in the config file to download the images from blob storage, download the model file from blob storage, and then run prediction on these images.  

```
sh active_learning_predict_no_train.sh ../config_usgs19_pred20191021.ini
```
