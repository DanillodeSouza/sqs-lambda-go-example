package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	example "github.com/DanillodeSouza/sqs-lambda-go-example/example"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handle(ctx context.Context, sqsEvent events.SQSEvent) error {
	config := example.NewConfig()
	logger, err := example.NewLogger(config.LogLevel)
	if err != nil {
		panic(err)
	}
	defer logger.Sync()

	for _, message := range sqsEvent.Records {
		start := time.Now()
		var transactionID string

		if transactionIDStruct, ok := message.MessageAttributes["transaction-id"]; ok {
			transactionID = *transactionIDStruct.StringValue
		}

		extras := make(map[string]string)
		extras["message-body"] = message.Body

		messageData := make(map[string]string)
		err = json.Unmarshal([]byte(message.Body), &messageData)
		if err != nil {
			example.LogError(logger, start, transactionID, fmt.Sprintf("Unmarshal message data error: %s", err.Error()), extras)
			return err
		}

		userID, err := strconv.Atoi(messageData["ID"])
		if err != nil {
			example.LogError(logger, start, transactionID, fmt.Sprintf("User ID string to int conversion error: %s", err.Error()), extras)
			return err
		}

		fmt.Sprintf("%d", userID)

		example.LogDebug(logger, transactionID, extras)
		example.LogProcessedResult(logger, start, transactionID, extras)
	}
	return nil
}

func main() {
	lambda.Start(handle)
}
