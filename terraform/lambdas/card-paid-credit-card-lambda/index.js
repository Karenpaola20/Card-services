import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  QueryCommand,
  UpdateCommand,
  PutCommand
} from "@aws-sdk/lib-dynamodb";
import { v4 as uuidv4 } from "uuid";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const sqs = new SQSClient({});

export const handler = async (event) => {

  try {

    const cardId = event.pathParameters.card_id;
    const body = JSON.parse(event.body);

    const { merchant, amount } = body;

    if (!merchant || !amount) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "merchant and amount are required"
        })
      };
    }

    const cardResult = await dynamo.send(new QueryCommand({
      TableName: process.env.CARD_TABLE,
      KeyConditionExpression: "#uuid = :uuid",
      ExpressionAttributeNames: {
        "#uuid": "uuid"
      },
      ExpressionAttributeValues: {
        ":uuid": cardId
      }
    }));

    const card = cardResult.Items?.[0];

    if (!card) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: "Card not found"
        })
      };
    }

    if (card.type !== "CREDIT") {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Only credit cards can be paid"
        })
      };
    }

    if (card.status !== "ACTIVATED") {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Card not activated"
        })
      };
    }

    if (amount > card.balance) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Payment exceeds used balance"
        })
      };
    }

    const newBalance = card.balance - amount;

    await dynamo.send(new UpdateCommand({
      TableName: process.env.CARD_TABLE,
      Key: {
        uuid: card.uuid,
        createdAt: card.createdAt
      },
      UpdateExpression: "SET balance = :balance",
      ExpressionAttributeValues: {
        ":balance": newBalance
      }
    }));

    const transaction = {
      uuid: uuidv4(),
      cardId: cardId,
      merchant: merchant,
      amount: amount,
      type: "PAYMENT_BALANCE",
      createdAt: new Date().toISOString()
    };

    await dynamo.send(new PutCommand({
      TableName: process.env.TRANSACTION_TABLE,
      Item: transaction
    }));

    const notificationMessage = {
      type: "TRANSACTION.PAID",
      data: {
        date: transaction.createdAt,
        merchant: merchant,
        amount: amount,
        email: "kbuelvas899@gmail.com"
      }
    };

    await sqs.send(new SendMessageCommand({
      QueueUrl: process.env.NOTIFICATION_QUEUE_URL,
      MessageBody: JSON.stringify(notificationMessage)
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Credit card payment successful",
        newBalance: newBalance
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