const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const eventbridge = new AWS.EventBridge();
const cloudwatch = new AWS.CloudWatch(); 

exports.handler = async (event) => {
    console.log('Lambda: Procesar y Almacenar Pedidos invocada');
    console.log('Evento SQS recibido:', JSON.stringify(event, null, 2));

    for (const record of event.Records) {
        let orderData;
        try {
            orderData = JSON.parse(record.body);
            console.log('Procesando pedido:', orderData.orderId);

            await cloudwatch.putMetricData({
                MetricData: [
                    {
                        MetricName: 'OrderProcessingStarted',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'processOrder' }],
                        Unit: 'Count',
                        Value: 1.0
                    }
                ],
                Namespace: 'ReyGasExpress/Metrics'
            }).promise();
            console.log(`Métrica OrderProcessingStarted publicada para ${orderData.orderId}`);

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
                    ttl: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60)
                }
            };

            await dynamodb.put(dynamoParams).promise();
            console.log('Pedido guardado en DynamoDB:', orderData.orderId);

            await cloudwatch.putMetricData({
                MetricData: [
                    {
                        MetricName: 'DynamoDBPutSuccess',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'processOrder' }],
                        Unit: 'Count',
                        Value: 1.0
                    }
                ],
                Namespace: 'ReyGasExpress/Metrics'
            }).promise();
            console.log('Métrica DynamoDBPutSuccess publicada.');

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
            console.log('Evento enviado a EventBridge para análisis:', orderData.orderId);

            await cloudwatch.putMetricData({
                MetricData: [
                    {
                        MetricName: 'EventBridgePutSuccess',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'processOrder' }],
                        Unit: 'Count',
                        Value: 1.0
                    }
                ],
                Namespace: 'ReyGasExpress/Metrics'
            }).promise();
            console.log('Métrica EventBridgePutSuccess publicada.');

        } catch (error) {
            console.error(`ERROR en processOrder para pedido ${orderData ? orderData.orderId : 'desconocido'}:`, error);

            await cloudwatch.putMetricData({
                MetricData: [
                    {
                        MetricName: 'ProcessingError',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'processOrder' }],
                        Unit: 'Count',
                        Value: 1.0
                    }
                ],
                Namespace: 'ReyGasExpress/Metrics'
            }).promise();
            console.log('Métrica ProcessingError publicada.');

            if (error.code === 'ResourceNotFoundException' || error.code === 'ProvisionedThroughputExceededException' || error.message.includes("connection error")) {
                 console.error('ERROR de CONEXIÓN/SERVICIO en processOrder:', error);
                 await cloudwatch.putMetricData({
                    MetricData: [
                        {
                            MetricName: 'DynamoDBConnectionError',
                            Dimensions: [{ Name: 'LambdaFunction', Value: 'processOrder' }],
                            Unit: 'Count',
                            Value: 1.0
                        }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                 }).promise();
            }

            throw error; 
        }
    }

    return { statusCode: 200 };
};