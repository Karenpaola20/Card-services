import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { v4 as uuidv4 } from "uuid";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

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
    }

};