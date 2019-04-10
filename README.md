# AWS Lambda Function for OpenCV

This project illustrates how to create an AWS Lambda Function using Python and OpenCV to grayscale an image in S3 and save it back to S3. The Python OpenCV library is provided via a Lambda Layer which reduces the size of the lambda function and enables the function code to be rendered in the Lambda code viewer in the AWS console.

## USAGE:

### Preliminary AWS CLI Setup: 
Setup credentials for AWS CLI (see http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)

Create IAM Role with Lambda and S3 access:
```
# Create a role with S3 and lambda exec access
ROLE_NAME=lambda-opencv_study
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document '{"Version":"2012-10-17","Statement":{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}}'
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $ROLE_NAME
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole --role-name $ROLE_NAME
```

### Option #1 - Deploy Lambda Function with dependencies included.

1. Edit the Lambda function code to do whatevery you want it to do.
```

vi app.py
```

2. Install libraries in the package directory with the --target option. It's recommended that you run this command on linux, not MacOS, since the Lambda runtime env is Amazon Linux.
```
python3 -m pip install opencv-python --target package/
```

3. Package the library into a ZIP archive
```
cd package
zip -r9 ../app.zip .
cd ..
```

4. Add your function code to the archive:
```
zip -g app.zip app.py
```

5. Deploy the lambda function:
```
# Create the lambda function:
FUNCTION_NAME=opencv_study
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r ".Account")
BUCKET_NAME=ianwow
aws s3 cp app.zip s3://$BUCKET_NAME
aws lambda create-function --function-name $FUNCTION_NAME --timeout 10 --role arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME --handler app.lambda_handler --region us-west-2 --runtime python3.6 --environment "Variables={BUCKET_NAME=$BUCKET_NAME,S3_KEY=$S3_KEY}" --code S3Bucket="$BUCKET_NAME",S3Key="app.zip"
```

One of the side effects of this approach is that the applciation code together with the dependencies exceeds 3MB. So, you cannot view the application code in the AWS Lambda Function editor. See deployment Option #2 (below) to workaround this error:

![images/editor_error.png]

### Option #2 - Deploy Lambda Function with libraries as Lambda Layers.

1. Edit the Lambda function code to do whatevery you want it to do.
```
vi app.py
```

2. Install libraries in the package directory with the --target option. 
```
python3 -m pip install opencv-python --target python/
```

3. Package the library into a ZIP archive. This will be extracted to /opt/python in the Lambda runtime environment (which is Amazon Linux).
```
zip -r9 ./cv2-python36.zip python/
```

4. Upload the library as a Lambda Layer.
```
LAMBDA_LAYERS_BUCKET=lambda-layers-$ACCOUNT_ID
aws s3 mb s3://$LAMBDA_LAYERS_BUCKET
aws s3 cp cv2-python36.zip s3://$LAMBDA_LAYERS_BUCKET
aws lambda publish-layer-version --layer-name cv2 --description "Open CV" --content S3Bucket=$LAMBDA_LAYERS_BUCKET,S3Key=cv2-python36.zip --compatible-runtimes python3.6
```

5. Create the lambda function:
```
rm -f app.zip
zip -g app.zip app.py
```

6. Deploy the lambda function:
```
# Create the Lambda Function:
FUNCTION_NAME=opencv_study
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r ".Account")
BUCKET_NAME=ianwow
aws s3 cp app.zip s3://$BUCKET_NAME
aws lambda create-function --function-name $FUNCTION_NAME --timeout 10 --role arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME --handler app.lambda_handler --region us-west-2 --runtime python3.6 --environment "Variables={BUCKET_NAME=$BUCKET_NAME,S3_KEY=$S3_KEY}" --code S3Bucket="$BUCKET_NAME",S3Key="app.zip"
```

7. Attach the cv2 lambda layer to our lambda function:
```
LAYER=$(aws lambda list-layer-versions --layer-name cv2 | jq -r '.LayerVersions[0].LayerVersionArn')
aws lambda update-function-configuration --function-name $FUNCTION_NAME --layers $LAYER
```

### Test the Lambda Function:
Our lambda function requires an image as input. Copy an image to S3, like this:
```
aws s3 cp ./my_image.jpg s3://ianwow/images/my_image.jpg
```
Then invoke the lambda function:
```
aws lambda invoke --function-name $FUNCTION_NAME --log-type Tail outputfile.txt
cat outputfile.txt
```

You should see output like this:
```
{"statusCode": 200, "body": "{\"message\": \"image saved to s3://ianwow/my_image-gray.jpg\"}"}
```

aws s3 cp ./my_image.jpg s3://ianwow/my_image-gray.jpg
open my_image-gray.jpg

<img src=my_image.jpg width="200"> <img src=my_image-gray.jpg width="200">

### Clean up resources
```
aws s3 rm s3://ianwow/my_image-gray.jpg
rm my_image-gray.jpg
rm -rf ./app.zip ./python/
aws lambda delete-function --function-name $FUNCTION_NAME
LAYER_VERSION=$(aws lambda list-layer-versions --layer-name cv2 | jq -r '.LayerVersions[0].Version')
aws lambda delete-layer-version --layer-name cv2 --version-number $LAYER_VERSION
aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole --role-name $ROLE_NAME
aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --role-name $ROLE_NAME
aws iam delete-role --role-name $ROLE_NAME
```