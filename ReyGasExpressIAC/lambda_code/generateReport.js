const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const sns = new AWS.SNS();
const cloudwatch = new AWS.CloudWatch();

exports.handler = async (event) => {
    console.log('Lambda: Generar Documento de Reporte de preferencias invocada');
    console.log('Evento SNS recibido:', JSON.stringify(event, null, 2));

    let customerIdForLogs = 'unknown_customer';

    try {
        await cloudwatch.putMetricData({
            MetricData: [{
                MetricName: 'ReportGenerationStarted',
                Dimensions: [{ Name: 'LambdaFunction', Value: 'generateReport' }],
                Unit: 'Count',
                Value: 1.0
            }],
            Namespace: 'ReyGasExpress/Metrics'
        }).promise();
        console.log('Métrica ReportGenerationStarted publicada.');

        for (const record of event.Records) {
            const snsMessage = JSON.parse(record.Sns.Message);
            const { customerId, s3Location, type } = snsMessage;
            customerIdForLogs = customerId;

            console.log(`Iniciando generación de reporte para cliente: ${customerId}`);

            const s3Params = {
                Bucket: process.env.ANALYSIS_BUCKET_NAME,
                Key: s3Location.replace(`s3://${process.env.ANALYSIS_BUCKET_NAME}/`, '')
            };

            let analysisData;
            try {
                analysisData = await s3.getObject(s3Params).promise();
                console.log(`Datos de análisis descargados de S3: ${s3Location} para cliente ${customerId}.`);
            } catch (s3Error) {
                console.error(`ERROR al descargar análisis de S3 para ${customerId}:`, s3Error);

                await cloudwatch.putMetricData({
                    MetricData: [
                        { MetricName: 'S3DownloadError', Dimensions: [{ Name: 'LambdaFunction', Value: 'generateReport' }], Unit: 'Count', Value: 1.0 },
                        { MetricName: 'ConnectionError', Dimensions: [{ Name: 'Service', Value: 'S3' }], Unit: 'Count', Value: 1.0 }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
                throw s3Error;
            }
            const analysis = JSON.parse(analysisData.Body.toString());

            console.log(`Generando HTML para reporte de cliente ${customerId}...`);
            const reportHtml = generateHtmlReport(analysis);
            console.log(`HTML del reporte generado para cliente ${customerId}.`);

            const reportKey = `reports/${customerId}/${Date.now()}_preferences_report.html`;
            try {
                await s3.putObject({
                    Bucket: process.env.REPORTS_BUCKET_NAME,
                    Key: reportKey,
                    Body: reportHtml,
                    ContentType: 'text/html',
                    ACL: 'private'
                }).promise();
                console.log('Reporte generado y guardado en S3:', reportKey);
            
                await cloudwatch.putMetricData({
                    MetricData: [{
                        MetricName: 'S3ReportUploadSuccess',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'generateReport' }],
                        Unit: 'Count',
                        Value: 1.0
                    }],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
            } catch (s3UploadError) {
                console.error(`ERROR al guardar reporte en S3 para ${customerId}:`, s3UploadError);
        
                await cloudwatch.putMetricData({
                    MetricData: [
                        { MetricName: 'S3ReportUploadError', Dimensions: [{ Name: 'LambdaFunction', Value: 'generateReport' }], Unit: 'Count', Value: 1.0 },
                        { MetricName: 'ConnectionError', Dimensions: [{ Name: 'Service', Value: 'S3' }], Unit: 'Count', Value: 1.0 }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
                throw s3UploadError;
            }

            console.log(`Publicando mensaje SNS para envío de email de reporte de cliente ${customerId}...`);
            await sns.publish({
                TopicArn: process.env.EMAIL_TOPIC_ARN,
                Message: JSON.stringify({
                    type: 'report-ready',
                    customerId,
                    reportLocation: `s3://${process.env.REPORTS_BUCKET_NAME}/${reportKey}`,
                    reportType: 'preferences',
                    generatedAt: new Date().toISOString()
                }),
                Subject: `Reporte de preferencias generado - Cliente ${customerId}`
            }).promise();
            console.log(`Notificación SNS enviada para envío de email de reporte de cliente ${customerId}.`);
            
            await cloudwatch.putMetricData({
                MetricData: [{
                    MetricName: 'EmailNotificationSent',
                    Dimensions: [{ Name: 'LambdaFunction', Value: 'generateReport' }],
                    Unit: 'Count',
                    Value: 1.0
                }],
                Namespace: 'ReyGasExpress/Metrics'
            }).promise();
        }

        await cloudwatch.putMetricData({
            MetricData: [{
                MetricName: 'ReportGenerationSuccess',
                Dimensions: [{ Name: 'LambdaFunction', Value: 'generateReport' }],
                Unit: 'Count',
                Value: 1.0
            }],
            Namespace: 'ReyGasExpress/Metrics'
        }).promise();
        console.log('FIN de generateReport. Éxito.');
        return { statusCode: 200 };

    } catch (error) {
        console.error(`ERROR CRÍTICO en generateReport para cliente ${customerIdForLogs}:`, error);
        
        await cloudwatch.putMetricData({
            MetricData: [{
                MetricName: 'ReportGenerationError',
                Dimensions: [{ Name: 'LambdaFunction', Value: 'generateReport' }],
                Unit: 'Count',
                Value: 1.0
            }],
            Namespace: 'ReyGasExpress/Metrics'
        }).promise();
        throw error;
    }
};

function generateHtmlReport(analysis) {
    return `
<!DOCTYPE html>
<html>
<head>
    <title>Reporte de Preferencias - Cliente ${analysis.customerId}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; color: #333; }
        .header { background-color: #f4f4f4; padding: 20px; border-bottom: 1px solid #ddd; }
        .header h1 { margin: 0; color: #0056b3; }
        .section { margin: 30px 0; padding: 15px; border: 1px solid #eee; border-radius: 8px; background-color: #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
        .section h2 { color: #0056b3; border-bottom: 2px solid #0056b3; padding-bottom: 10px; margin-top: 0; }
        .chart { background-color: #f9f9f9; padding: 15px; border-radius: 4px; border: 1px dashed #ccc; }
        ul { list-style-type: disc; margin-left: 20px; }
        li { margin-bottom: 5px; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #777; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Reporte de Análisis de Preferencias</h1>
        <p>Cliente: <strong>${analysis.customerId}</strong></p>
        <p>Fecha de Generación: ${analysis.analysisDate ? new Date(analysis.analysisDate).toLocaleDateString() : 'N/A'}</p>
    </div>
    
    <div class="section">
        <h2>Resumen del Historial de Pedidos</h2>
        <p>Total de órdenes analizadas: <strong>${analysis.totalOrders || 0}</strong></p>
        <p>Valor promedio de orden: <strong>$${analysis.preferences?.averageOrderValue?.toFixed(2) || 'N/A'}</strong></p>
    </div>
    
    <div class="section">
        <h2>Categorías Favoritas</h2>
        <div class="chart">
            ${analysis.preferences?.favoriteCategories && analysis.preferences.favoriteCategories.length > 0 ?
                analysis.preferences.favoriteCategories.map(([cat, count]) =>
                    `<p><strong>${cat}</strong>: ${count} órdenes</p>`
                ).join('') :
                '<p>No hay datos suficientes para determinar categorías favoritas.</p>'
            }
        </div>
    </div>
    
    <div class="section">
        <h2>Recomendaciones Personalizadas</h2>
        <ul>
            ${analysis.recommendations?.suggestedItems && analysis.recommendations.suggestedItems.length > 0 ?
                analysis.recommendations.suggestedItems.map(item => `<li>${item}</li>`).join('') :
                '<li>No hay recomendaciones disponibles en este momento.</li>'
            }
            ${analysis.recommendations?.crossSellOpportunities && analysis.recommendations.crossSellOpportunities.length > 0 ?
                `<li>Oportunidades de Venta Cruzada: ${analysis.recommendations.crossSellOpportunities.join(', ')}</li>` : ''
            }
            ${analysis.recommendations?.seasonalRecommendations && analysis.recommendations.seasonalRecommendations.length > 0 ?
                `<li>Recomendaciones de Temporada: ${analysis.recommendations.seasonalRecommendations.join(', ')}</li>` : ''
            }
        </ul>
    </div>

    <div class="section">
        <h2>Tendencias Identificadas</h2>
        <ul>
            <li>Frecuencia de Orden: ${analysis.trends?.orderFrequency || 'N/A'}</li>
            <li>Tendencia de Gasto: ${analysis.trends?.spendingTrend || 'N/A'}</li>
            ${analysis.trends?.categoryShifts && analysis.trends.categoryShifts.length > 0 ?
                `<li>Cambios de Categoría: ${analysis.trends.categoryShifts.join(', ')}</li>` : ''
            }
        </ul>
        <p>Detección de Cambios Significativos en Preferencias: <strong>${analysis.preferences?.significantChanges ? 'Sí' : 'No'}</strong></p>
    </div>

    <div class="footer">
        <p>Este reporte fue generado automáticamente por el sistema ReyGasExpress.</p>
        <p>&copy; ${new Date().getFullYear()} ReyGasExpress. Todos los derechos reservados.</p>
    </div>
</body>
</html>`;
}