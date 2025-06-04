const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const eventbridge = new AWS.EventBridge();

exports.handler = async (event) => {
    console.log('Lambda: Procesar y Almacenar Pedidos invocada');
    console.log('Evento SQS recibido:', JSON.stringify(event, null, 2));
    
    try {
        for (const record of event.Records) {
            const orderData = JSON.parse(record.body);
            console.log('Procesando pedido:', orderData.orderId);

            // Guardar en DynamoDB
            const dynamoParams = {
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
                    ttl: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60) // 1 año TTL
                }
            };

            await dynamodb.put(dynamoParams).promise();
            console.log('Pedido guardado en DynamoDB:', orderData.orderId);

            // Enviar evento a EventBridge para análisis de preferencias
            const eventParams = {
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
            };

            await eventbridge.putEvents(eventParams).promise();
            console.log('Evento enviado a EventBridge para análisis');
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en processOrder:', error);
        throw error; // Esto hará que SQS reintente el mensaje
    }
};