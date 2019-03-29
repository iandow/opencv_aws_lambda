# AWS Lambda Function for OpenCV

This project illustrates how to create an AWS Lambda Function using Python and OpenCV to grayscale an image in S3 and save it back to S3. The Python OpenCV library is provided via a Lambda Layer, which reduces the size of our lambda function and enables us to use the code viewer in the Lamda Function web UI.

## USAGE:

## Preliminary AWS CLI Setup: 
Setup credentials for AWS CLI (see http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)

### Create IAM Role with Lambda and S3 access:

```
ROLE_NAME=lambda-opencv_study
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document '{"Version":"2012-10-17","Statement":{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}}'
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $ROLE_NAME
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole --role-name $ROLE_NAME
```

### Create Lambda Function:
```
FUNCTION_NAME=opencv_study
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r ".Account")
BUCKET_NAME=ianwow
S3_KEY=images/my_image.jpg
aws lambda create-function --function-name $FUNCTION_NAME --timeout 10 --role arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME --handler app.lambda_handler --region us-west-2 --environment "Variables={BUCKET_NAME=$BUCKET_NAME,S3_KEY=$S3_KEY}" --zip-file fileb://./app.zip --runtime python3.6
```

***(optional)*** - If you change the code in app.py, update the Lambda function like this:
```
zip -g app.zip app.py
aws lambda update-function-code --function-name ianwow_study --zip-file fileb://app.zip
```

### Create Lambda Layers:
Install python libraries using Amazon Linux, since that's what Lambdas run in:
```
python3 -m pip install opencv-python -t python
zip -r9 ./cv2-python36.zip python
```

Upload and attach the Lambda Layer to the Lambda Function. We upload this layer to s3 instead of reference it via fileb:// because [direct uploads must be less than 50MB](https://docs.aws.amazon.com/lambda/latest/dg/limits.html) and our opencv zip is close to exceeding that.
```
LAMBDA_LAYERS_BUCKET=lambda-layers-$ACCOUNT_ID
aws s3 mb s3://$LAMBDA_LAYERS_BUCKET
aws s3 cp cv2-python36.zip s3://$LAMBDA_LAYERS_BUCKET
aws lambda publish-layer-version --layer-name cv2 --description "Open CV" --content S3Bucket=$LAMBDA_LAYERS_BUCKET,S3Key=cv2-python36.zip --compatible-runtimes python3.6
```

### Attach Lambda Layers:

```
LAYER=$(aws lambda list-layer-versions --layer-name cv2 | jq -r '.LayerVersions[0].LayerVersionArn')
aws lambda update-function-configuration --function-name $FUNCTION_NAME --layers $LAYER
```

### Invoke the Lambda Function:
First copy an image to S3, like this:
```
aws s3 cp ~/my_image.jpg s3://ianwow/images/my_image.jpg
```
Then invoke the Lambda function:
```
aws lambda invoke --function-name $FUNCTION_NAME --log-type Tail --payload '{"key1":"value1", "key2":"value2"}' outputfile.txt
cat outputfile.txt
```

You should see output like this:
```
{"statusCode": 200, "body": "{\"message\": \"image saved to s3://ianwow/my_image-gray.jpg\"}"}
```

<img src=my_image.jpg width="200"> <img src=my_image-gray.jpg width="200">

### Clean up resources
```
aws lambda delete-function --function-name $FUNCTION_NAME
LAYER_VERSION=$(aws lambda list-layer-versions --layer-name cv2 | jq -r '.LayerVersions[0].Version')
aws lambda delete-layer-version --layer-name cv2 --version-number $LAYER_VERSION
aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole --role-name $ROLE_NAME
aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $ROLE_NAME
aws iam delete-role --role-name $ROLE_NAME
```