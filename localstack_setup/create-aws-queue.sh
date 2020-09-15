#!/bin/bash
# Script to create sqs queue

SQS_QUEUE_NAME=example # Sqs queue name

# Creating sqs queue
echo "Creating queue"

awslocal sqs create-queue \
    --queue-name $SQS_QUEUE_NAME \
    && echo "Created" || echo "Failed to create"

echo "Sqs initialization completed"
