import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  QueryCommand,
  UpdateCommand,
  PutCommand
} from "@aws-sdk/lib-dynamodb";
import { v4 as uuidv4 } from "uuid";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {

  try {

    const body = JSON.parse(event.body);

    const { merchant, cardId, amount } = body;

    if (!merchant || !cardId || !amount) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "merchant, cardId and amount are required"
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

    if (card.status !== "ACTIVATED") {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Card not activated"
        })
      };
    }

    let newBalance = card.balance;

    // DEBIT
    if (card.type === "DEBIT") {

      if (card.balance < amount) {
        return {
          statusCode: 400,
          body: JSON.stringify({
            message: "Insufficient balance"
          })
        };
      }

      newBalance = card.balance - amount;
    }

    // CREDIT
    if (card.type === "CREDIT") {

      if ((card.balance + amount) > card.limit) {
        return {
          statusCode: 400,
          body: JSON.stringify({
            message: "Credit limit exceeded"
          })
        };
      }

      newBalance = card.balance + amount;
    }

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
      type: "PURCHASE",
      createdAt: new Date().toISOString()
    };

    await dynamo.send(new PutCommand({
      TableName: process.env.TRANSACTION_TABLE,
      Item: transaction
    }));

    // RESPUESTA FINAL
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Purchase completed",
        transaction: transaction
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