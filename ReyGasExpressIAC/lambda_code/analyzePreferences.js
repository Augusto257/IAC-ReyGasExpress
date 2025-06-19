const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();
const sns = new AWS.SNS();

exports.handler = async (event) => {
    console.log('Lambda: Analizar Preferencias invocada');
    console.log('Evento EventBridge recibido:', JSON.stringify(event, null, 2));
    
    try {
        for (const record of event.Records || [event]) {
            const eventDetail = record.detail || event.detail;
            const { orderId, customerId, preferences, items } = eventDetail;

            const queryParams = {
                TableName: process.env.ORDERS_TABLE_NAME,
                IndexName: 'customer-index',
                KeyConditionExpression: 'customerId = :customerId',
                ExpressionAttributeValues: {
                    ':customerId': customerId
                },
                Limit: 50
            };

            const historicalData = await dynamodb.query(queryParams).promise();
            
            const analysis = {
                customerId,
                analysisDate: new Date().toISOString(),
                totalOrders: historicalData.Count,
                preferences: analyzeCustomerPreferences(historicalData.Items, preferences),
                recommendations: generateRecommendations(historicalData.Items, items),
                trends: identifyTrends(historicalData.Items)
            };

            const s3Key = `preferences-analysis/${customerId}/${Date.now()}.json`;
            await s3.putObject({
                Bucket: process.env.ANALYSIS_BUCKET_NAME,
                Key: s3Key,
                Body: JSON.stringify(analysis, null, 2),
                ContentType: 'application/json'
            }).promise();

            console.log('Análisis guardado en S3:', s3Key);

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
            }
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en analyzePreferences:', error);
        throw error;
    }
};

function analyzeCustomerPreferences(historicalOrders, currentPreferences) {
    const categoryFrequency = {};
    const priceRanges = [];
    
    historicalOrders.forEach(order => {
        order.items.forEach(item => {
            categoryFrequency[item.category] = (categoryFrequency[item.category] || 0) + 1;
        });
        priceRanges.push(order.totalAmount);
    });

    return {
        favoriteCategories: Object.entries(categoryFrequency)
            .sort(([,a], [,b]) => b - a)
            .slice(0, 3),
        averageOrderValue: priceRanges.reduce((a, b) => a + b, 0) / priceRanges.length,
        currentPreferences,
        significantChanges: detectPreferenceChanges(historicalOrders, currentPreferences)
    };
}

function generateRecommendations(historicalOrders, currentItems) {
    return {
        suggestedItems: ['Recomendación basada en historial'],
        crossSellOpportunities: ['Productos complementarios'],
        seasonalRecommendations: ['Productos de temporada']
    };
}

function identifyTrends(historicalOrders) {
    return {
        orderFrequency: 'monthly',
        spendingTrend: 'increasing',
        categoryShifts: []
    };
}

function detectPreferenceChanges(historical, current) {
    return Math.random() > 0.8;
}