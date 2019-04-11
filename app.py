import json
import logging
import boto3
import botocore
import os

def lambda_handler(event, context):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    logger.info('event parameter: {}'.format(event))
    tmp_filename='/tmp/my_image.jpg'
    gray_filename='my_image-gray.jpg'

    s3 = boto3.resource('s3')
    BUCKET_NAME = os.environ.get("BUCKET_NAME")
    S3_KEY = os.environ.get("S3_KEY")
    
    import numpy
    import cv2
    
    try:
        s3.Bucket(BUCKET_NAME).download_file(S3_KEY, tmp_filename)
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            print("The object does not exist: s3://" + BUCKET_NAME + S3_KEY)
        else:
            raise

    image = cv2.imread(tmp_filename) 
    image_gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    cv2.imwrite(tmp_filename, image_gray) 
    
    s3 = boto3.client('s3')
    s3.upload_file('/tmp/my_image.jpg',BUCKET_NAME,gray_filename)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "image saved to s3://"+BUCKET_NAME+"/"+gray_filename,
        }),
    }

