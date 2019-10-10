#!/bin/bash
# Source environmental variables
set -a
sed -i 's/\r//g' $1
. $1
set +a
# Updating vars in config file
envsubst < $1 > cur_config.ini
# Update images from blob storage
echo "Updating Blob Folder"
python ${python_file_directory}/update_blob_folder.py cur_config.ini
# Use inference graph to create predictions on untagged images
echo "Creating new predictions"
python ${python_file_directory}/create_predictions.py cur_config.ini
echo "Calculating performance"
python ${python_file_directory}/map_validation.py cur_config.ini
# Rename predictions and inference graph based on timestamp and upload
echo "Uploading new data"
az storage blob upload --container-name $label_container_name --file $untagged_output --name totag_$(date +%s).csv --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
az storage blob upload --container-name $label_container_name --file $validation_output --name performance_$(date +%s).csv --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
