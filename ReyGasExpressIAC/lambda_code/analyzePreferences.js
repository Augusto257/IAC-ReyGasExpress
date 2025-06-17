const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();
const sns = new AWS.SNS();
const cloudwatch = new AWS.CloudWatch(); 

exports.handler = async (event) => {
    console.log('Lambda: Analizar Preferencias invocada');
    console.log('Evento EventBridge recibido:', JSON.stringify(event, null, 2));

    let customerId = 'unknown'; 

    try {
        for (const record of event.Records || [event]) {
            const eventDetail = record.detail || event.detail;
            const { orderId, customerId: currentCustomerId, preferences, items } = eventDetail;
            customerId = currentCustomerId || 'unknown';

            console.log(`Iniciando análisis para cliente: ${customerId}`);

            await cloudwatch.putMetricData({
                MetricData: [
                    {
                        MetricName: 'PreferenceAnalysisStarted',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'analyzePreferences' }],
                        Unit: 'Count',
                        Value: 1.0
                    }
                ],
                Namespace: 'ReyGasExpress/Metrics'
            }).promise();
            console.log('Métrica PreferenceAnalysisStarted publicada.');

            const queryParams = {
                TableName: process.env.ORDERS_TABLE_NAME,
                IndexName: 'customer-index',
                KeyConditionExpression: 'customerId = :customerId',
                ExpressionAttributeValues: {
                    ':customerId': customerId
                },
                Limit: 50
            };

            let historicalData;
            try {
                historicalData = await dynamodb.query(queryParams).promise();
                console.log(`Datos históricos de DynamoDB obtenidos para ${customerId}. Items: ${historicalData.Count}`);

                await cloudwatch.putMetricData({
                    MetricData: [
                        {
                            MetricName: 'DynamoDBQuerySuccess',
                            Dimensions: [{ Name: 'LambdaFunction', Value: 'analyzePreferences' }],
                            Unit: 'Count',
                            Value: 1.0
                        }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
            } catch (dbError) {
                console.error(`ERROR al consultar DynamoDB para ${customerId}:`, dbError);
                await cloudwatch.putMetricData({
                    MetricData: [
                        {
                            MetricName: 'DynamoDBQueryError',
                            Dimensions: [{ Name: 'LambdaFunction', Value: 'analyzePreferences' }],
                            Unit: 'Count',
                            Value: 1.0
                        },
                         {
                            MetricName: 'ConnectionError',
                            Dimensions: [{ Name: 'Service', Value: 'DynamoDB' }],
                            Unit: 'Count',
                            Value: 1.0
                        }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
                throw dbError;
            }
            
            const analysis = {
                customerId,
                analysisDate: new Date().toISOString(),
                totalOrders: historicalData.Count,
                preferences: analyzeCustomerPreferences(historicalData.Items, preferences),
                recommendations: generateRecommendations(historicalData.Items, items),
                trends: identifyTrends(historicalData.Items)
            };

            const s3Key = `preferences-analysis/${customerId}/${Date.now()}.json`;
            try {
                await s3.putObject({
                    Bucket: process.env.ANALYSIS_BUCKET_NAME,
                    Key: s3Key,
                    Body: JSON.stringify(analysis, null, 2),
                    ContentType: 'application/json'
                }).promise();
                console.log('Análisis guardado en S3:', s3Key);

                await cloudwatch.putMetricData({
                    MetricData: [
                        {
                            MetricName: 'S3PutSuccess',
                            Dimensions: [{ Name: 'LambdaFunction', Value: 'analyzePreferences' }],
                            Unit: 'Count',
                            Value: 1.0
                        }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
            } catch (s3Error) {
                console.error(`ERROR al guardar en S3 para ${customerId}:`, s3Error);
                await cloudwatch.putMetricData({
                    MetricData: [
                        {
                            MetricName: 'S3WriteError',
                            Dimensions: [{ Name: 'LambdaFunction', Value: 'analyzePreferences' }],
                            Unit: 'Count',
                            Value: 1.0
                        },
                         {
                            MetricName: 'ConnectionError',
                            Dimensions: [{ Name: 'Service', Value: 'S3' }],
                            Unit: 'Count',
                            Value: 1.0
                        }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
                throw s3Error;
            }

            if (analysis.preferences.significantChanges || analysis.totalOrders % 10 === 0) {
                await sns.publish({
                    TopicArn: process.env.REPORT_TOPIC_ARN,
                    Message: JSON.stringify({
                        type: 'preference-analysis-complete',
                        customerId,
                        s3Location: `s3://${process.env.ANALYSIS_BUCKET_NAME}/${s3Key}`,
                        requiresReport: true
                    }),
                    Subject: `Análisis de preferencias completado - Cliente ${customerId}`
                }).promise();
                console.log(`Notificación SNS enviada para reporte de ${customerId}`);

                await cloudwatch.putMetricData({
                    MetricData: [
                        {
                            MetricName: 'ReportNotificationSent',
                            Dimensions: [{ Name: 'LambdaFunction', Value: 'analyzePreferences' }],
                            Unit: 'Count',
                            Value: 1.0
                        }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
            }
        }

        console.log('FIN de analyzePreferences. Éxito.');
        return { statusCode: 200 };

    } catch (error) {
        console.error(`ERROR CRÍTICO en analyzePreferences para cliente ${customerId}:`, error);

        await cloudwatch.putMetricData({
            MetricData: [
                {
                    MetricName: 'AnalysisError',
                    Dimensions: [{ Name: 'LambdaFunction', Value: 'analyzePreferences' }],
                    Unit: 'Count',
                    Value: 1.0
                }
            ],
            Namespace: 'ReyGasExpress/Metrics'
        }).promise();

        throw error;
    }
};