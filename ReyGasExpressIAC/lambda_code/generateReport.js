const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const sns = new AWS.SNS();

exports.handler = async (event) => {
    console.log('Lambda: Generar Documento de Reporte de preferencias invocada');
    console.log('Evento SNS recibido:', JSON.stringify(event, null, 2));
    
    try {
        for (const record of event.Records) {
            const snsMessage = JSON.parse(record.Sns.Message);
            const { customerId, s3Location, type } = snsMessage;

            // Descargar datos de análisis desde S3
            const s3Params = {
                Bucket: process.env.ANALYSIS_BUCKET_NAME,
                Key: s3Location.replace(`s3://${process.env.ANALYSIS_BUCKET_NAME}/`, '')
            };

            const analysisData = await s3.getObject(s3Params).promise();
            const analysis = JSON.parse(analysisData.Body.toString());

            // Generar reporte HTML
            const reportHtml = generateHtmlReport(analysis);
            
            // Guardar reporte en S3
            const reportKey = `reports/${customerId}/${Date.now()}_preferences_report.html`;
            await s3.putObject({
                Bucket: process.env.REPORTS_BUCKET_NAME,
                Key: reportKey,
                Body: reportHtml,
                ContentType: 'text/html',
                ACL: 'private'
            }).promise();

            console.log('Reporte generado y guardado:', reportKey);

            // Notificar para envío por email
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
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en generateReport:', error);
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
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f4f4f4; padding: 20px; }
        .section { margin: 20px 0; }
        .chart { background-color: #f9f9f9; padding: 15px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Reporte de Análisis de Preferencias</h1>
        <p>Cliente: ${analysis.customerId}</p>
        <p>Fecha: ${analysis.analysisDate}</p>
    </div>
    
    <div class="section">
        <h2>Resumen</h2>
        <p>Total de órdenes analizadas: ${analysis.totalOrders}</p>
        <p>Valor promedio de orden: $${analysis.preferences.averageOrderValue?.toFixed(2) || 'N/A'}</p>
    </div>
    
    <div class="section">
        <h2>Categorías Favoritas</h2>
        <div class="chart">
            ${analysis.preferences.favoriteCategories?.map(([cat, count]) => 
                `<p>${cat}: ${count} órdenes</p>`
            ).join('') || 'No hay datos suficientes'}
        </div>
    </div>
    
    <div class="section">
        <h2>Recomendaciones</h2>
        <ul>
            ${analysis.recommendations?.suggestedItems?.map(item => `<li>${item}</li>`).join('') || '<li>No hay recomendaciones disponibles</li>'}
        </ul>
    </div>
</body>
</html>`;
}