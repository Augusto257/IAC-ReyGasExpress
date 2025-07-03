const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');

const s3 = new S3Client({ region: process.env.AWS_REGION });
const sns = new SNSClient({ region: process.env.AWS_REGION });

exports.handler = async (event) => {
    console.log('Lambda: Generar Documento de Reporte de preferencias invocada');
    console.log('Evento SNS recibido:', JSON.stringify(event, null, 2));
    
    try {
        for (const record of event.Records) {
            const snsMessage = JSON.parse(record.Sns.Message);
            const { customerId, s3Location, type } = snsMessage;

            const s3Params = {
                Bucket: process.env.ANALYSIS_BUCKET_NAME,
                Key: s3Location.replace(`s3://${process.env.ANALYSIS_BUCKET_NAME}/`, '')
            };

            const analysisData = await s3.send(new GetObjectCommand(s3Params));
            const analysis = JSON.parse(await analysisData.Body.transformToString());

            const reportHtml = generateHtmlReport(analysis);
            
            const reportKey = `reports/${customerId}/${Date.now()}_preferences_report.html`;
            await s3.send(new PutObjectCommand({
                Bucket: process.env.REPORTS_BUCKET_NAME,
                Key: reportKey,
                Body: reportHtml,
                ContentType: 'text/html',
                ACL: 'private'
            }));

            console.log('Reporte generado y guardado:', reportKey);

            await sns.send(new PublishCommand({
                TopicArn: process.env.EMAIL_TOPIC_ARN,
                Message: JSON.stringify({
                    type: 'report-ready',
                    customerId,
                    reportLocation: `s3://${process.env.REPORTS_BUCKET_NAME}/${reportKey}`,
                    reportType: 'preferences',
                    generatedAt: new Date().toISOString()
                }),
                Subject: `Reporte de preferencias generado - Cliente ${customerId}`
            }));
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en generateReport:', error);
        throw error;
    }
};

function generateHtmlReport(analysis) {
    const favoriteCategoriesHtml = analysis.preferences.favoriteCategories?.map(([cat, count]) => 
        `<p>${cat}: ${count} órdenes</p>`
    ).join('') || 'No hay datos suficientes';

    const suggestedItemsHtml = analysis.recommendations?.suggestedItems?.map(item => 
        `<li>${item}</li>`
    ).join('') || '<li>No hay recomendaciones disponibles</li>';

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
            ${favoriteCategoriesHtml}
        </div>
    </div>
    
    <div class="section">
        <h2>Recomendaciones</h2>
        <ul>
            ${suggestedItemsHtml}
        </ul>
    </div>
</body>
</html>`;
}