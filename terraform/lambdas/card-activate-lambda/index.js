import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  ScanCommand,
  QueryCommand,
  UpdateCommand
} from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const sqs = new SQSClient({});

export const handler = async (event) => {

  try {

    const body = JSON.parse(event.body);
    const { userId } = body;

    if (!userId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "userId is required"
        })
      };
    }

    const cards = await dynamo.send(new ScanCommand({
      TableName: process.env.CARD_TABLE,
      FilterExpression: "user_id = :user",
      ExpressionAttributeValues: {
        ":user": userId
      }
    }));

    const debitCard = cards.Items.find(c => c.type === "DEBIT");
    const creditCard = cards.Items.find(c => c.type === "CREDIT");

    if (!debitCard || !creditCard) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: "User cards not found"
        })
      };
    }

    const transactions = await dynamo.send(new QueryCommand({
      TableName: process.env.TRANSACTION_TABLE,
      IndexName: "cardId-index",
      KeyConditionExpression: "cardId = :cardId",
      FilterExpression: "#type = :purchase",
      ExpressionAttributeNames: {
        "#type": "type"
      },
      ExpressionAttributeValues: {
        ":cardId": debitCard.uuid,
        ":purchase": "PURCHASE"
      }
    }));

    const totalTransactions = transactions.Items?.length || 0;

    if (totalTransactions < 10) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Card requires at least 10 transactions",
          transactions: totalTransactions
        })
      };
    }

    await dynamo.send(new UpdateCommand({
      TableName: process.env.CARD_TABLE,
      Key: {
        uuid: creditCard.uuid,
        createdAt: creditCard.createdAt
      },
      UpdateExpression: "SET #status = :status",
      ExpressionAttributeNames: {
        "#status": "status"
      },
      ExpressionAttributeValues: {
        ":status": "ACTIVATED"
      }
    }));

    await sqs.send(new SendMessageCommand({
      QueueUrl: process.env.NOTIFICATION_QUEUE_URL,
      MessageBody: JSON.stringify({
        type: "CARD.ACTIVATE",
        data: {
          email: "kbuelvas899@gmail.com",
          date: new Date().toISOString(),
          Type: "CREDIT",
          amount: creditCard.balance,
          userId: userId
        }
      })
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Credit card activated successfully"
      })
    };

  } catch (error) {

    console.error(error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Internal server error",
        error: error.message
      })
    };

  }

};