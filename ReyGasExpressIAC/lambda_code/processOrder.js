// const { DynamoDBClient } = require('@aws-sdk/client-dynamodb'); // Eliminado
// const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb'); // Eliminado
const { EventBridgeClient, PutEventsCommand } = require('@aws-sdk/client-eventbridge');

const REGION = process.env.AWS_REGION;

// const dynamodbClient = new DynamoDBClient({ region: REGION }); // Eliminado
// const ddbDocClient = DynamoDBDocumentClient.from(dynamodbClient); // Eliminado

const eventbridge = new EventBridgeClient({ region: REGION });

exports.handler = async (event) => {
    console.log('Lambda: Procesar y Almacenar Pedidos invocada (modo temporal sin DB)');
    console.log('Evento recibido:', JSON.stringify(event, null, 2));

    try {
        // La fuente de eventos SQS ha sido eliminada.
        // Asumiremos que el evento contendrá directamente los registros, o se adaptará en el futuro.
        // Por ahora, para la eliminación, esta Lambda no almacenará nada.

        for (const record of event.Records) { // Asumimos que los eventos de SQS vienen en Records, aunque SQS será eliminado.
                                             // Esto se ajustará cuando se defina la nueva fuente de eventos (ej. directamente desde registerOrder o EventBridge)
            const orderData = JSON.parse(record.body);
            console.log('Simulando procesamiento de pedido (sin DB):', orderData.orderId);

            // Lógica de DynamoDB eliminada
            // const putCommand = new PutCommand({ ... });
            // await ddbDocClient.send(putCommand);
            // console.log('Pedido *no* guardado en DynamoDB (eliminado):', orderData.orderId);

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
            console.log('Evento "Order Processed" enviado a EventBridge para análisis');
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en processOrder (modo temporal sin DB):', error);
        throw error;
    }
};