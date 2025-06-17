const AWS = require('aws-sdk');
const ses = new AWS.SES();
const s3 = new AWS.S3();
const cloudwatch = new AWS.CloudWatch();

exports.handler = async (event) => {
    console.log('Lambda: Enviar Reporte por correo invocada');
    console.log('Evento SNS recibido:', JSON.stringify(event, null, 2));

    let customerIdForLogs = 'unknown_customer'; 

    try {
        await cloudwatch.putMetricData({
            MetricData: [{
                MetricName: 'EmailSendStarted',
                Dimensions: [{ Name: 'LambdaFunction', Value: 'sendEmailReport' }],
                Unit: 'Count',
                Value: 1.0
            }],
            Namespace: 'ReyGasExpress/Metrics'
        }).promise();
        console.log('Métrica EmailSendStarted publicada.');

        for (const record of event.Records) {
            const snsMessage = JSON.parse(record.Sns.Message);
            const { customerId, reportLocation, reportType, generatedAt } = snsMessage;
            customerIdForLogs = customerId;

            console.log(`Iniciando envío de email para reporte de cliente: ${customerId}`);

            const s3Params = {
                Bucket: process.env.REPORTS_BUCKET_NAME,
                Key: reportLocation.replace(`s3://${process.env.REPORTS_BUCKET_NAME}/`, '')
            };

            let reportData;
            try {
                reportData = await s3.getObject(s3Params).promise();
                console.log(`Reporte descargado de S3: ${reportLocation} para cliente ${customerId}.`);
            } catch (s3Error) {
                console.error(`ERROR al descargar reporte de S3 para ${customerId}:`, s3Error);
                await cloudwatch.putMetricData({
                    MetricData: [
                        { MetricName: 'S3DownloadError', Dimensions: [{ Name: 'LambdaFunction', Value: 'sendEmailReport' }], Unit: 'Count', Value: 1.0 },
                        { MetricName: 'ConnectionError', Dimensions: [{ Name: 'Service', Value: 'S3' }], Unit: 'Count', Value: 1.0 }
                    ],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
                throw s3Error;
            }
            const reportHtml = reportData.Body.toString();

            const emailParams = {
                Source: process.env.FROM_EMAIL,
                Destination: {
                    ToAddresses: [process.env.TO_EMAIL || `cliente-${customerId}@example.com`]
                },
                Message: {
                    Subject: {
                        Data: `Reporte de ${reportType} - ${new Date(generatedAt).toLocaleDateString()}`,
                        Charset: 'UTF-8'
                    },
                    Body: {
                        Html: {
                            Data: reportHtml,
                            Charset: 'UTF-8'
                        },
                        Text: {
                            Data: `Reporte de ${reportType} generado para el cliente ${customerId}. Ver versión HTML para detalles completos.`,
                            Charset: 'UTF-8'
                        }
                    }
                }
            };

            console.log(`Intentando enviar email a ${emailParams.Destination.ToAddresses[0]} para cliente ${customerId}.`);
            try {
                const result = await ses.sendEmail(emailParams).promise();
                console.log('Email enviado exitosamente:', result.MessageId);
        
                await cloudwatch.putMetricData({
                    MetricData: [{
                        MetricName: 'EmailSendSuccess',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'sendEmailReport' }],
                        Unit: 'Count',
                        Value: 1.0
                    }],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();
            } catch (sesError) {
                console.error(`ERROR al enviar email para cliente ${customerId}:`, sesError);
                
                await cloudwatch.putMetricData({
                    MetricData: [{
                        MetricName: 'EmailSendError',
                        Dimensions: [{ Name: 'LambdaFunction', Value: 'sendEmailReport' }],
                        Unit: 'Count',
                        Value: 1.0
                    }],
                    Namespace: 'ReyGasExpress/Metrics'
                }).promise();

                if (sesError.code === 'MessageRejected' || sesError.code === 'InvalidParameterValue' || sesError.code === 'AccessDeniedException') {
                    console.log('Email no pudo ser enviado - Posiblemente el email remitente/destinatario no está verificado en SES o faltan permisos.');
            
                    await cloudwatch.putMetricData({
                        MetricData: [{
                            MetricName: 'SESVerificationError',
                            Dimensions: [{ Name: 'LambdaFunction', Value: 'sendEmailReport' }],
                            Unit: 'Count',
                            Value: 1.0
                        }],
                        Namespace: 'ReyGasExpress/Metrics'
                    }).promise();
                    
                    return { statusCode: 200, message: 'Email handling completed with warnings/errors (SES issue).' };
                }
                throw sesError;
            }
        }

        console.log('FIN de sendEmailReport. Éxito.');
        return { statusCode: 200 };

    } catch (error) {
        console.error(`ERROR CRÍTICO en sendEmailReport para cliente ${customerIdForLogs}:`, error);

        await cloudwatch.putMetricData({
            MetricData: [{
                MetricName: 'EmailProcessError',
                Dimensions: [{ Name: 'LambdaFunction', Value: 'sendEmailReport' }],
                Unit: 'Count',
                Value: 1.0
            }],
            Namespace: 'ReyGasExpress/Metrics'
        }).promise();
        throw error;
    }
};