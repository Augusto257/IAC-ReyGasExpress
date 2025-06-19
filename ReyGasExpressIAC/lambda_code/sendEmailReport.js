const AWS = require('aws-sdk');
const ses = new AWS.SES();
const s3 = new AWS.S3();

exports.handler = async (event) => {
    console.log('Lambda: Enviar Reporte por correo invocada');
    console.log('Evento SNS recibido:', JSON.stringify(event, null, 2));
    
    try {
        for (const record of event.Records) {
            const snsMessage = JSON.parse(record.Sns.Message);
            const { customerId, reportLocation, reportType, generatedAt } = snsMessage;

            // Obtener el reporte desde S3
            const s3Params = {
                Bucket: process.env.REPORTS_BUCKET_NAME,
                Key: reportLocation.replace(`s3://${process.env.REPORTS_BUCKET_NAME}/`, '')
            };

            const reportData = await s3.getObject(s3Params).promise();
            const reportHtml = reportData.Body.toString();

            // Configurar parámetros del email
            const emailParams = {
                Source: process.env.FROM_EMAIL, // Email verificado en SES
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

            // Enviar email
            const result = await ses.sendEmail(emailParams).promise();
            console.log('Email enviado:', result.MessageId);
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en sendEmailReport:', error);
        
        // Si es error de SES (email no verificado), loguear pero no fallar
        if (error.code === 'MessageRejected' || error.code === 'InvalidParameterValue') {
            console.log('Email no pudo ser enviado - posiblemente email no verificado en SES');
            return { statusCode: 200, message: 'Email handling completed with warnings' };
        }
        
        throw error;
    }
};