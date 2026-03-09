import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  QueryCommand
} from "@aws-sdk/lib-dynamodb";

import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const ses = new SESClient({});

export const handler = async (event) => {

  try {

    const cardId = event.pathParameters?.card_id;

    const { start, end } = event.queryStringParameters || {};

    if (!start || !end) {
        return {
            statusCode: 400,
            body: JSON.stringify({
                message: "Start and end are required"
            })
        }
    }

    const result = await dynamo.send(new QueryCommand({
      TableName: process.env.TRANSACTION_TABLE,
      IndexName: "cardId-createdAt-index",
      KeyConditionExpression: "cardId = :cardId AND createdAt BETWEEN :start AND :end",
      ExpressionAttributeValues: {
        ":cardId": cardId,
        ":start": start,
        ":end": end
      }
    }));

    const transactions = result.Items || [];

    let csv = "uuid,merchant,amount,type,createdAt\n";

    for (const t of transactions) {

      csv += `${t.uuid},${t.merchant},${t.amount},${t.type},${t.createdAt}\n`;

    }

    const emailParams = {

      Source: process.env.SES_EMAIL,

      Destination: {
        ToAddresses: ["kbuelvas899@gmail.com"]
      },

      Message: {

        Subject: {
          Data: "Card Transactions Report"
        },

        Body: {
          Text: {
            Data: `Transactions report\n\n${csv}`
          }
        }

      }

    };

    await ses.send(new SendEmailCommand(emailParams));

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Report sent to email"
      })
    };

  } catch (error) {

    console.error(error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Internal server error"
      })
    };

  }

};