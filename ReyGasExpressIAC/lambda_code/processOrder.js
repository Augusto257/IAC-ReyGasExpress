const { EventBridgeClient, PutEventsCommand } = require('@aws-sdk/client-eventbridge');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { Client } = require('pg');

const REGION = process.env.AWS_REGION;

const eventbridge = new EventBridgeClient({ region: REGION });
const secretsManager = new SecretsManagerClient({ region: REGION });

const DB_HOST = process.env.DB_HOST;
const DB_PORT = process.env.DB_PORT;
const DB_NAME = process.env.DB_NAME;
const DB_USERNAME = process.env.DB_USERNAME;
const DB_PASSWORD_SECRET_ARN = process.env.DB_PASSWORD_SECRET_ARN;
const EVENT_BUS_NAME = process.env.EVENT_BUS_NAME;

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

async function initializeDatabase(client) {
    const createTableQuery = `
        CREATE TABLE IF NOT EXISTS orders (
            order_id VARCHAR(255) PRIMARY KEY,
            customer_id VARCHAR(255) NOT NULL,
            items JSONB NOT NULL,
            total_amount NUMERIC(10, 2) NOT NULL,
            preferences JSONB,
            status VARCHAR(50) NOT NULL,
            order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    `;
    try {
        await client.query(createTableQuery);
        console.log('Tabla "orders" verificada/creada exitosamente.');
    } catch (error) {
        console.error('Error al crear/verificar tabla "orders":', error);
        throw error;
    }
}

exports.handler = async (event) => {
    console.log('Lambda: Procesar y Almacenar Pedidos invocada');
    console.log('Evento recibido:', JSON.stringify(event, null, 2));

    try {
        const client = await connectToDatabase();
        await initializeDatabase(client);

        for (const record of event.Records) {
            const orderData = JSON.parse(record.body);
            console.log('Procesando pedido:', orderData.orderId);

            const insertQuery = `
                INSERT INTO orders (order_id, customer_id, items, total_amount, preferences, status)
                VALUES ($1, $2, $3, $4, $5, $6)
                ON CONFLICT (order_id) DO UPDATE SET
                    items = EXCLUDED.items,
                    total_amount = EXCLUDED.total_amount,
                    preferences = EXCLUDED.preferences,
                    status = EXCLUDED.status,
                    order_date = EXCLUDED.order_date;
            `;
            const values = [
                orderData.orderId,
                orderData.customerId,
                JSON.stringify(orderData.items),
                orderData.totalAmount,
                JSON.stringify(orderData.preferences || {}),
                'processed'
            ];

            await client.query(insertQuery, values);
            console.log('Pedido guardado en PostgreSQL:', orderData.orderId);

            const putEventsCommand = new PutEventsCommand({
                Entries: [{
                    Source: 'orders.system',
                    DetailType: 'Order Processed',
                    Detail: JSON.stringify({
                        orderId: orderData.orderId,
                        customerId: orderData.customerId,
                        preferences: orderData.preferences,
                        items: orderData.items,
                        status: 'processed'
                    }),
                    EventBusName: EVENT_BUS_NAME
                }]
            });

            await eventbridge.send(putEventsCommand);
            console.log('Evento "Order Processed" enviado a EventBridge para análisis');
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en processOrder:', error);
        throw error;
    }
};