const AWS = require('aws-sdk');
const sqs = new AWS.SQS();

exports.handler = async (event) => {
    console.log('Lambda: Registrar Datos de Pedido invocada');
    console.log('Evento recibido:', JSON.stringify(event, null, 2));

    try {
        // Extraer datos del evento (API Gateway)
        const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;

        // Validar campos requeridos del pedido
        const { customerId, items, totalAmount, preferences } = body;

        if (!customerId || !items || !totalAmount) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                },
                body: JSON.stringify({
                    error: 'Campos requeridos: customerId, items, totalAmount'
                }),
            };
        }

        // Preparar mensaje para SQS
        const orderMessage = {
            orderId: `order-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            customerId,
            items,
            totalAmount,
            preferences: preferences || {},
            timestamp: new Date().toISOString(),
            status: 'pending'
        };

        // Enviar a SQS
        const sqsParams = {
            QueueUrl: process.env.SQS_QUEUE_URL,
            MessageBody: JSON.stringify(orderMessage),
            MessageAttributes: {
                'OrderType': {
                    DataType: 'String',
                    StringValue: 'new-order'
                }
            }
        };

        await sqs.sendMessage(sqsParams).promise();
        console.log('Mensaje enviado a SQS:', orderMessage.orderId);

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
            },
            body: JSON.stringify({
                message: 'Pedido recibido y encolado para procesamiento.',
                orderId: orderMessage.orderId
            }),
        };

    } catch (error) {
        console.error('Error en registerOrder:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
            },
            body: JSON.stringify({
                error: 'Error interno del servidor',
                details: error.message
            }),
        };
    }
};