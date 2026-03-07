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

    const cardId = event.pathParameters.card_id;
    const body = JSON.parse(event.body);

    if (!body.amount || !body.merchant) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "amount and merchant are required"
        })
      };
    }

    // Buscar la tarjeta
    const cardResult = await dynamo.send(new QueryCommand({
      TableName: process.env.CARD_TABLE,
      KeyConditionExpression: "#u = :uuid",
      ExpressionAttributeNames: {
        "#u": "uuid"
      },
      ExpressionAttributeValues: {
        ":uuid": cardId
      }
    }));

    const card = cardResult.Items?.[0];

    if (!card) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: "Card not found" })
      };
    }

    if (card.type !== "DEBIT") {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Only debit cards can receive balance"
        })
      };
    }

    if (card.status !== "ACTIVATED") {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Card is not activated"
        })
      };
    }

    const amount = Number(body.amount);

    if (amount <= 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Amount must be greater than 0"
        })
      };
    }

    const newBalance = Number(card.balance) + amount;

    // Actualizar balance
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

    // Aqui crea transacción
    const transaction = {
      uuid: uuidv4(),
      cardId: cardId,
      amount: amount,
      merchant: body.merchant,
      type: "SAVING",
      createdAt: new Date().toISOString()
    };

    await dynamo.send(new PutCommand({
      TableName: process.env.TRANSACTION_TABLE,
      Item: transaction
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Balance added successfully",
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