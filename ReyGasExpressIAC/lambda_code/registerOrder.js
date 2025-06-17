const AWS = require('aws-sdk');
const sqs = new AWS.SQS();
const cloudwatch = new AWS.CloudWatch();

exports.handler = async (event) => {
    console.log('Lambda: Registrar Datos de Pedido invocada');
    console.log('Evento recibido:', JSON.stringify(event, null, 2));

    let statusCode = 200;
    let message = 'Pedido recibido y encolado para procesamiento.';
    let orderId = null;
    let errorDetails = null;

    try {
        await cloudwatch.putMetricData({
            MetricData: [
                {
                    MetricName: 'ApiGatewayRequests',
                    Dimensions: [
                        { Name: 'LambdaFunction', Value: 'registerOrder' },
                        { Name: 'HttpMethod', Value: event.httpMethod || 'UNKNOWN' }
                    ],
                    Unit: 'Count',
                    Value: 1.0
                }
            ],
            Namespace: 'ReyGasExpress/Metrics'
        }).promise();
        console.log('Métrica ApiGatewayRequests publicada.');

        const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;

        const { customerId, items, totalAmount, preferences } = body;

        if (!customerId || !items || !totalAmount) {
            statusCode = 400;
            message = 'Campos requeridos: customerId, items, totalAmount';
            errorDetails = message;
            console.error(`ERROR: ${message}`);

            await cloudwatch.putMetricData({
                MetricData: [
                    {
                        MetricName: 'ValidationError',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'registerOrder' }],
                        Unit: 'Count',
                        Value: 1.0
                    }
                ],
                Namespace: 'ReyGasExpress/Metrics'
            }).promise();
            console.log('Métrica ValidationError publicada.');

        } else {
            const orderMessage = {
                orderId: `order-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
                customerId,
                items,
                totalAmount,
                preferences: preferences || {},
                timestamp: new Date().toISOString(),
                status: 'pending'
            };
            orderId = orderMessage.orderId;

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

            await cloudwatch.putMetricData({
                MetricData: [
                    {
                        MetricName: 'SqsMessageSent',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'registerOrder' }],
                        Unit: 'Count',
                        Value: 1.0
                    }
                ],
                Namespace: 'ReyGasExpress/Metrics'
            }).promise();
            console.log('Métrica SqsMessageSent publicada.');
        }

    } catch (error) {
        console.error('ERROR en registerOrder:', error);
        statusCode = 500;
        message = 'Error interno del servidor';
        errorDetails = error.message;

        await cloudwatch.putMetricData({
            MetricData: [
                {
                    MetricName: 'InternalError',
                    Dimensions: [{ Name: 'LambdaFunction', Value: 'registerOrder' }],
                    Unit: 'Count',
                    Value: 1.0
                }
            ],
            Namespace: 'ReyGasExpress/Metrics'
        }).promise();
        console.log('Métrica InternalError publicada.');

    } finally {
        console.log(`FIN de registerOrder. Estado: ${statusCode}, Mensaje: ${message}`);
        return {
            statusCode: statusCode,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
            },
            body: JSON.stringify({
                message: message,
                orderId: orderId,
                details: errorDetails
            }),
        };
    }
};