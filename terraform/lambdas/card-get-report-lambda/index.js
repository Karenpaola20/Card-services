import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";

import { S3Client, PutObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

import crypto from "crypto";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const s3 = new S3Client({});
const sqs = new SQSClient({});

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
      };
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

    const fileName = `reports/${crypto.randomUUID()}.csv`;

    await s3.send(new PutObjectCommand({
      Bucket: process.env.REPORT_BUCKET,
      Key: fileName,
      Body: csv,
      ContentType: "text/csv"
    }));

    const command = new GetObjectCommand({
      Bucket: process.env.REPORT_BUCKET,
      Key: fileName
    });

    const url = await getSignedUrl(s3, command, {
      expiresIn: 3600
    });

    const notificationMessage = {
      type: "REPORT.ACTIVITY",
      data: {
        email: "kbuelvas899@gmail.com",
        date: new Date().toISOString(),
        url: url
      }
    };

    await sqs.send(new SendMessageCommand({
      QueueUrl: process.env.NOTIFICATION_QUEUE_URL,
      MessageBody: JSON.stringify(notificationMessage)
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Report generated successfully",
        url: url
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