const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { Client } = require('pg');

const REGION = process.env.AWS_REGION;

const s3 = new S3Client({ region: REGION });
const sns = new SNSClient({ region: REGION });
const secretsManager = new SecretsManagerClient({ region: REGION });

const DB_HOST = process.env.DB_HOST;
const DB_PORT = process.env.DB_PORT;
const DB_NAME = process.env.DB_NAME;
const DB_USERNAME = process.env.DB_USERNAME;
const DB_PASSWORD_SECRET_ARN = process.env.DB_PASSWORD_SECRET_ARN;
const ANALYSIS_BUCKET_NAME = process.env.ANALYSIS_BUCKET_NAME;
const REPORT_TOPIC_ARN = process.env.REPORT_TOPIC_ARN;

let dbClient;

async function getDbCredentials() {
    try {
        const command = new GetSecretValueCommand({ SecretId: DB_PASSWORD_SECRET_ARN });
        const data = await secretsManager.send(command);
        if ('SecretString' in data) {
            return JSON.parse(data.SecretString);
        }
        return { password: data.SecretBinary || data.SecretString };
    } catch (error) {
        console.error('Error al obtener credenciales de Secrets Manager:', error);
        throw error;
    }
}

async function connectToDatabase() {
    if (dbClient && !dbClient._ending) {
        console.log('Reutilizando conexión a la base de datos existente.');
        return dbClient;
    }

    console.log('Estableciendo nueva conexión a la base de datos.');
    try {
        const credentials = await getDbCredentials();
        dbClient = new Client({
            host: DB_HOST,
            port: DB_PORT,
            database: DB_NAME,
            user: DB_USERNAME,
            password: credentials.password || credentials,
            ssl: {
                rejectUnauthorized: false
            }
        });
        await dbClient.connect();
        console.log('Conexión a la base de datos PostgreSQL establecida.');
        return dbClient;
    } catch (error) {
        console.error('Error al conectar a la base de datos PostgreSQL:', error);
        throw error;
    }
}

exports.handler = async (event) => {
    console.log('Lambda: Analizar Preferencias invocada');
    console.log('Evento EventBridge recibido:', JSON.stringify(event, null, 2));
    
    try {
        const client = await connectToDatabase();

        const eventDetail = event.detail || (event.Records && event.Records[0] && JSON.parse(event.Records[0].body));
        
        if (!eventDetail) {
            console.warn('No se encontró detalle del evento para análisis de preferencias.');
            return { statusCode: 204, body: 'No event detail found.' };
        }

        const { customerId, preferences, items } = eventDetail;

        const queryHistoricalData = 'SELECT * FROM orders WHERE customer_id = $1 ORDER BY order_date DESC;';
        const result = await client.query(queryHistoricalData, [customerId]);
        const historicalOrders = result.rows.map(row => ({
            ...row,
            items: JSON.parse(row.items),
            preferences: row.preferences ? JSON.parse(row.preferences) : {} 
        }));
        console.log(`Pedidos históricos encontrados para ${customerId}: ${historicalOrders.length}`);
        
        const analysis = {
            customerId,
            analysisDate: new Date().toISOString(),
            totalOrders: historicalOrders.length,
            preferences: analyzeCustomerPreferences(historicalOrders, preferences),
            recommendations: generateRecommendations(historicalOrders, items),
            trends: identifyTrends(historicalOrders)
        };

        const s3Key = `preferences-analysis/${customerId}/${Date.now()}.json`;
        await s3.send(new PutObjectCommand({
            Bucket: ANALYSIS_BUCKET_NAME,
            Key: s3Key,
            Body: JSON.stringify(analysis, null, 2),
            ContentType: 'application/json'
        }));

        console.log('Análisis guardado en S3:', s3Key);

        if (analysis.preferences.significantChanges || analysis.totalOrders % 10 === 0) {
            await sns.send(new PublishCommand({
                TopicArn: REPORT_TOPIC_ARN,
                Message: JSON.stringify({
                    type: 'preference-analysis-complete',
                    customerId,
                    s3Location: `s3://${ANALYSIS_BUCKET_NAME}/${s3Key}`,
                    requiresReport: true
                }),
                Subject: `Análisis de preferencias completado - Cliente ${customerId}`
            }));
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
        priceRanges.push(parseFloat(order.total_amount));
    });

    return {
        favoriteCategories: Object.entries(categoryFrequency)
            .sort(([,a], [,b]) => b - a)
            .slice(0, 3),
        averageOrderValue: priceRanges.length > 0 ? (priceRanges.reduce((a, b) => a + b, 0) / priceRanges.length) : 0,
        currentPreferences,
        significantChanges: detectPreferenceChanges(historicalOrders, currentPreferences)
    };
}

function generateRecommendations(historicalOrders, currentItems) {
    const popularItems = {};
    historicalOrders.forEach(order => {
        order.items.forEach(item => {
            popularItems[item.productId] = (popularItems[item.productId] || 0) + 1;
        });
    });

    const sortedPopularItems = Object.entries(popularItems)
        .sort(([,a], [,b]) => b - a)
        .map(([id]) => `Item ${id}`);

    return {
        suggestedItems: sortedPopularItems.length > 0 ? sortedPopularItems.slice(0, 3) : ['No hay sugerencias aún'],
        crossSellOpportunities: ['Productos complementarios (futura mejora)'],
        seasonalRecommendations: ['Productos de temporada (futura mejora)']
    };
}

function identifyTrends(historicalOrders) {
    const monthlyOrders = {};
    historicalOrders.forEach(order => {
        const month = new Date(order.order_date).toLocaleString('en-us', { month: 'short', year: 'numeric' });
        monthlyOrders[month] = (monthlyOrders[month] || 0) + 1;
    });

    return {
        orderFrequency: monthlyOrders,
        spendingTrend: 'analysis needed',
        categoryShifts: []
    };
}

function detectPreferenceChanges(historical, current) {
    return historical.length > 5 && Math.random() > 0.7;
}