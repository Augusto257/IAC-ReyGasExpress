const { CloudWatchClient, PutMetricDataCommand } = require('@aws-sdk/client-cloudwatch');

const cloudwatch = new CloudWatchClient({ region: process.env.AWS_REGION });

function log(level, message, context = {}) {
    const entry = {
        level,
        message,
        timestamp: new Date().toISOString(),
        function: 'registerOrder',
        ...context
    };
    console.log(JSON.stringify(entry));
}

exports.handler = async (event) => {
    log('INFO', 'Lambda iniciada', { event });

    let statusCode = 200;
    let response = {
        message: 'Pedido recibido. Enviando para procesamiento.',
        orderId: null,
        details: null
    };

    try {
        await cloudwatch.send(new PutMetricDataCommand({
            Namespace: 'ReyGasExpress/Metrics',
            MetricData: [{
                MetricName: 'ApiGatewayRequests',
                Dimensions: [
                    { Name: 'Function', Value: 'registerOrder' },
                    { Name: 'Method', Value: event.httpMethod || 'UNKNOWN' }
                ],
                Unit: 'Count',
                Value: 1
            }]
        }));

        const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        const { customerId, items, totalAmount, preferences } = body;

        if (!customerId || !items || !totalAmount) {
            statusCode = 400;
            response.message = 'Datos incompletos';
            response.details = 'Campos requeridos: customerId, items, totalAmount';
            
            log('WARN', 'Validación fallida', { body });
            
            await cloudwatch.send(new PutMetricDataCommand({
                Namespace: 'ReyGasExpress/Metrics',
                MetricData: [{
                    MetricName: 'ValidationError',
                    Dimensions: [{ Name: 'Function', Value: 'registerOrder' }],
                    Unit: 'Count',
                    Value: 1
                }]
            }));
        } else {
            response.orderId = `order-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
            log('INFO', 'Pedido recibido y validado. Listo para ser procesado por otra Lambda.', { orderId: response.orderId });
        }

    } catch (error) {
        statusCode = 500;
        response.message = 'Error interno';
        response.details = error.message;
        
        log('ERROR', 'Error en registerOrder', { 
            error: error.message,
            stack: error.stack 
        });

        await cloudwatch.send(new PutMetricDataCommand({
            Namespace: 'ReyGasExpress/Metrics',
            MetricData: [{
                MetricName: 'InternalError',
                Dimensions: [
                    { Name: 'Function', Value: 'registerOrder' },
                    { Name: 'ErrorType', Value: error.name || 'Unknown' }
                ],
                Unit: 'Count',
                Value: 1
            }]
        }));
    }

    return {
        statusCode,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        body: JSON.stringify(response)
    };
};