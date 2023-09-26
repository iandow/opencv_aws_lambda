# AWS Lambda layer for OpenCV

## Build OpenCV library using Docker

```
git clone https://github.com/machafer/opencv_aws_lambda
cd opencv_aws_lambda
docker build --tag=lambda-layer-factory:latest .
docker run --rm -it -v $(pwd):/data lambda-layer-factory cp /packages/opencv-python-311.zip /data

```

## Upload layer file

```
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
FINAL_BUCKET=$(aws cloudformation describe-stack-resource --stack-name theme-park-backend --logical-resource-id FinalBucket --query "StackResourceDetail.PhysicalResourceId" --output text)
PROCESSING_BUCKET=$(aws cloudformation describe-stack-resource --stack-name theme-park-backend --logical-resource-id ProcessingBucket --query "StackResourceDetail.PhysicalResourceId" --output text)
UPLOAD_BUCKET=$(aws cloudformation describe-stack-resource --stack-name theme-park-backend --logical-resource-id UploadBucket --query "StackResourceDetail.PhysicalResourceId" --output text)
accountId=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .accountId)
s3_deploy_bucket="theme-park-sam-deploys-${accountId}"

aws s3 cp opencv-python-311.zip s3://$s3_deploy_bucket

aws lambda publish-layer-version --layer-name python-opencv-311 --description "OpenCV for Python 3.11" --content S3Bucket=$s3_deploy_bucket,S3Key=opencv-python-311.zip --compatible-runtimes python3.11
    
```

