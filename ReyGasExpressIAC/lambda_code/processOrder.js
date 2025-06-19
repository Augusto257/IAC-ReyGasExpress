const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { EventBridgeClient, PutEventsCommand } = require('@aws-sdk/client-eventbridge');

const REGION = process.env.AWS_REGION;

const dynamodbClient = new DynamoDBClient({ region: REGION });
const ddbDocClient = DynamoDBDocumentClient.from(dynamodbClient);

const eventbridge = new EventBridgeClient({ region: REGION });

exports.handler = async (event) => {
    console.log('Lambda: Procesar y Almacenar Pedidos invocada');
    console.log('Evento SQS recibido:', JSON.stringify(event, null, 2));

    try {
        for (const record of event.Records) {
            const orderData = JSON.parse(record.body);
            console.log('Procesando pedido:', orderData.orderId);

            const putCommand = new PutCommand({
                TableName: process.env.ORDERS_TABLE_NAME,
                Item: {
                    orderId: orderData.orderId,
                    customerId: orderData.customerId,
                    items: orderData.items,
                    totalAmount: orderData.totalAmount,
                    preferences: orderData.preferences,
                    status: 'processed',
                    createdAt: orderData.timestamp,
                    processedAt: new Date().toISOString(),
                    ttl: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60)
                }
            });

            await ddbDocClient.send(putCommand);
            console.log('Pedido guardado en DynamoDB:', orderData.orderId);

            const putEventsCommand = new PutEventsCommand({
                Entries: [{
                    Source: 'orders.system',
                    DetailType: 'Order Processed',
                    Detail: JSON.stringify({
                        orderId: orderData.orderId,
                        customerId: orderData.customerId,
                        preferences: orderData.preferences,
                        items: orderData.items
                    }),
                    EventBusName: process.env.EVENT_BUS_NAME || 'default'
                }]
            });

            await eventbridge.send(putEventsCommand);
            console.log('Evento enviado a EventBridge para análisis');
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en processOrder:', error);
        throw error;
    }
};