import logging
import azure.functions as func
from PIL import Image
import io
from azure.storage.blob import BlobServiceClient

def main(event: func.EventGridEvent):
    logging.info('Python EventGrid trigger function processed event: %s', event.subject)

    conn_str = func.get_binding_connection_string("AzureWebJobsStorage")
    thumbnail_container = func.get_binding_settings("THUMBNAIL_CONTAINER")

    # Parse blob URL from event
    blob_url = event.subject
    container_name = blob_url.split('/containers/')[1].split('/blobs/')[0]
    blob_name = blob_url.split('/blobs/')[1]

    # Download image
    blob_service = BlobServiceClient.from_connection_string(conn_str)
    blob_client = blob_service.get_blob_client(container=container_name, blob=blob_name)
    stream = io.BytesIO()
    blob_client.download_blob().readinto(stream)

    # Resize
    image = Image.open(stream)
    image.thumbnail((300, 300))
    output = io.BytesIO()
    image.save(output, format=image.format or 'JPEG')

    # Upload thumbnail
    thumb_name = f"thumb_{blob_name}"
    thumb_client = blob_service.get_blob_client(container=thumbnail_container, blob=thumb_name)
    thumb_client.upload_blob(output.getvalue(), overwrite=True)

    logging.info(f"Thumbnail created: {thumb_name}")