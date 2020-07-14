#!/bin/bash
# Source environmental variables
set -a
sed -i 's/\r//g' $1
. $1
set +a
# Updating vars in config file
envsubst < $1 > cur_config.ini
# Use inference graph to create predictions on untagged images
echo "Creating new predictions"
python ${python_file_directory}/create_predictions.py cur_config.ini
echo "Uploading new data"
# # az storage blob upload --container-name $label_container_name --file ${inference_output_dir}/frozen_inference_graph.pb --name model_$(date +%s).pb  --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
az storage blob upload --container-name $label_container_name --file $untagged_output --name totag_$(date +%s).csv --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
# az storage blob upload --container-name $label_container_name --file $validation_output --name performance_$(date +%s).csv --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
