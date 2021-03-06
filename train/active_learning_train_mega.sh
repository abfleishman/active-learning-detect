#!/bin/bash
# Source environmental variables
set -a
sed -i 's/\r//g' $1
. $1
set +a
# Updating vars in config file
envsubst < $1 > cur_config.ini
# Update images from blob storage
# echo "Updating Blob Folder"
# python ${python_file_directory}/update_blob_folder.py cur_config.ini
# # Create TFRecord from images + csv file on blob storage
# echo "Creating TF Record"
# python ${python_file_directory}/convert_tf_record.py cur_config.ini
# # Download tf model if it doesn't exist
if [ ! -d "$download_location/${model_name}" ]; then
  mkdir -p $download_location/${model_name}
  curl $tf_url --create-dirs -o ${download_location}/${model_name}/${model_name}_checkpoint.zip
  echo $download_location/${model_name}
  unzip -o ${download_location}/${model_name}/${model_name}_checkpoint.zip -d $download_location/${model_name}
  curl https://lilablobssc.blob.core.windows.net/models/camera_traps/megadetector/megadetector_v3.pb --create-dirs -o ${download_location}/${model_name}/${model_name}.pb
fi
if [ ! -z "$optional_pipeline_url" ]; then
  curl $optional_pipeline_url -o $pipeline_file
elif [ ! -f $pipeline_file ]; then
  cp ${download_location}/${model_name}/pipeline.config $pipeline_file
fi
echo "Making pipeline file from env vars"
temp_pipeline=${pipeline_file%.*}_temp.${pipeline_file##*.}
sed "s/${old_label_path//\//\\/}/${label_map_path//\//\\/}/g" $pipeline_file > $temp_pipeline
sed -i '\ \ gradient_clipping_by_norm:\ 10.0 a\ \ fine_tune_checkpoint: "PATH_TO_BE_CONFIGURED/model.ckpt"\n \ from_detection_checkpoint: true\n \ load_all_detection_checkpoint_vars: true\n \ num_steps: 15000' $temp_pipeline
sed -i "s/${old_train_path//\//\\/}/${tf_train_record//\//\\/}/g" $temp_pipeline
sed -i "s/${old_val_path//\//\\/}/${tf_val_record//\//\\/}/g" $temp_pipeline
sed -i "s/${old_checkpoint_path//\//\\/}/${fine_tune_checkpoint//\//\\/}/g" $temp_pipeline
sed -i "s/keep_checkpoint_every_n_hours:\ 1.0/keep_checkpoint_every_n_hours:\ 1/g" $temp_pipeline
sed -i "s/$num_steps_marker[[:space:]]*[[:digit:]]*/$num_steps_marker $train_iterations/g" $temp_pipeline
sed -i "s/$num_examples_marker[[:space:]]*[[:digit:]]*/$num_examples_marker $eval_iterations/g" $temp_pipeline
sed -i "s/$num_classes_marker[[:space:]]*[[:digit:]]*/$num_classes_marker $num_classes/g" $temp_pipeline

# # Train model on TFRecord
echo "Training model"
rm -rf $train_dir
python ${tf_location_legacy}/train.py --train_dir=$train_dir --pipeline_config_path=$temp_pipeline --logtostderr
# Export inference graph of model
echo "Exporting inference graph"
rm -rf $inference_output_dir
echo $temp_pipeline
echo ${train_dir}/model.ckpt-$train_iterations
echo $inference_output_dir
python ${tf_location}/export_inference_graph.py --input_type "image_tensor" --pipeline_config_path "$temp_pipeline" --trained_checkpoint_prefix "${train_dir}/model.ckpt-$train_iterations" --output_directory "$inference_output_dir"
# TODO: Validation on Model, keep track of MAP etc.
# Use inference graph to create predictions on untagged images
echo "Creating new predictions"
python ${python_file_directory}/create_predictions.py cur_config.ini
echo "Calculating performance"
python ${python_file_directory}/map_validation.py cur_config.ini
Rename predictions and inference graph based on timestamp and upload
echo "Uploading new data"
az storage blob upload --container-name $label_container_name --file ${inference_output_dir}/frozen_inference_graph.pb --name model_$(date +%s).pb  --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
az storage blob upload --container-name $label_container_name --file $untagged_output --name totag_$(date +%s).csv --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
az storage blob upload --container-name $label_container_name --file $validation_output --name performance_$(date +%s).csv --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY
