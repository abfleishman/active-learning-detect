from azure.storage.blob import BlockBlobService, ContentSettings

class BlobStorage():
    azure_storage_client = None
    
    #TODO: Verify the storage account is correct. Currently we get an unhelpful error message if you have a type in Storage Name
    @staticmethod
    def get_azure_storage_client(config):
        if BlobStorage.azure_storage_client is not None:
            return BlobStorage.azure_storage_client

        BlobStorage.azure_storage_client = BlockBlobService(
            config.get("storage_account"),
            account_key=config.get("storage_key")
        )

        return BlobStorage.azure_storage_client


def attempt_get_blob(blob_credentials, blob_name, blob_dest):
    if blob_credentials is None:
        print ("blob_credentials is None, can not get blob")
        return  False
    blob_service, container_name = blob_credentials
    is_successful = False
    print("Dest: {0}".format(blob_dest))
    try:
        blob_service.get_blob_to_path(container_name, blob_name, blob_dest)
        is_successful = True
    except:
        print("Error when getting blob")
        print("Src: {0} {1}".format(container_name, blob_name))


    return is_successful

