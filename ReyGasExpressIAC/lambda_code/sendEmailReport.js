const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');

const ses = new SESClient({ region: process.env.AWS_REGION });
const s3 = new S3Client({ region: process.env.AWS_REGION });

exports.handler = async (event) => {
    console.log('Lambda: Enviar Reporte por correo invocada');
    console.log('Evento SNS recibido:', JSON.stringify(event, null, 2));
    
    try {
        for (const record of event.Records) {
            const snsMessage = JSON.parse(record.Sns.Message);
            const { customerId, reportLocation, reportType, generatedAt } = snsMessage;

            const s3Params = {
                Bucket: process.env.REPORTS_BUCKET_NAME,
                Key: reportLocation.replace(`s3://${process.env.REPORTS_BUCKET_NAME}/`, '')
            };

            const reportData = await s3.send(new GetObjectCommand(s3Params));
            const reportHtml = await reportData.Body.transformToString();

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

            const result = await ses.send(new SendEmailCommand(emailParams));
            console.log('Email enviado:', result.MessageId);
        }

        return { statusCode: 200 };

    } catch (error) {
        console.error('Error en sendEmailReport:', error);
        
        if (error.Code === 'MessageRejected' || error.Code === 'InvalidParameterValue') {
            console.log('Email no pudo ser enviado - posiblemente email no verificado en SES');
            return { statusCode: 200, message: 'Email handling completed with warnings' };
        }
        
        throw error;
    }
};