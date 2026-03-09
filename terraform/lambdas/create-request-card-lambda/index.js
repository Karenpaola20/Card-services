import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { v4 as uuidv4 } from "uuid";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const sqs = new SQSClient({ region: "us-east-1" });

const NOTIFICATION_QUEUE = process.env.NOTIFICATION_QUEUE_URL;

export const handler = async (event) => {

    for (const record of event.Records) {

        const body = JSON.parse(record.body);

        const score = Math.floor(Math.random() * 101);

        const amount = 100 + (score / 100) * (10000000 - 100);

        const card = {
            uuid: uuidv4(),
            user_id: body.userId,
            type: body.request,
            status: body.request === "DEBIT" ? "ACTIVATED" : "PENDING",
            balance: body.request === "DEBIT" ? 0 : amount,
            createdAt: new Date().toISOString()
        };

        await dynamo.send(new PutCommand({
            TableName: process.env.CARD_TABLE,
            Item: card
        }));
        
        await sqs.send(
            new SendMessageCommand({
                QueueUrl: NOTIFICATION_QUEUE,
                MessageBody: JSON.stringify({
                    type: "CARD.CREATE",
                    data: {
                        date: card.createdAt,
                        type: card.type,
                        amount: card.balance,
                        email: "kbuelvas899@gmail.com"
                    }
                })
            })
        );
    }
};