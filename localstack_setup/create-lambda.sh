#!/bin/bash
# Script to create the lambda

LAMBDA_NAME=processor

# Creating lambda
echo "Creating lambda"

awslocal lambda create-function \
    --runtime go1.x \
    --handler lambda-processor \
    --role=arn:aws:iam:local \
    --zip-file fileb:///bin/linux_amd64/lambda-processor.zip \
    --function-name $LAMBDA_NAME \
    --environment '{
        "Variables":{
            "LOG_LEVEL":"debug"
        }
    }' \
    && echo "Created" || echo "Failed to create"

echo "Creating Event source mapping"
awslocal lambda create-event-source-mapping \
    --event-source-arn arn:aws:sqs:us-east-1:000000000000:example \
    --function-name $LAMBDA_NAME \
    && echo "Created event" || echo "Failed to create event"

echo "Lambda initialization completed"
