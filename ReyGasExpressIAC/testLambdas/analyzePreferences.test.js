const mockS3Send = jest.fn();
jest.mock('@aws-sdk/client-s3', () => ({ S3Client: jest.fn(() => ({ send: mockS3Send })), PutObjectCommand: jest.fn(i => i) }));

const mockSNSSend = jest.fn();
jest.mock('@aws-sdk/client-sns', () => ({ SNSClient: jest.fn(() => ({ send: mockSNSSend })), PublishCommand: jest.fn(i => i) }));

const mockSecretsManagerSend = jest.fn();
jest.mock('@aws-sdk/client-secrets-manager', () => ({ SecretsManagerClient: jest.fn(() => ({ send: mockSecretsManagerSend })), GetSecretValueCommand: jest.fn(i => i) }));

const mockPgConnect = jest.fn();
const mockPgQuery = jest.fn();
const mockPgClient = { connect: mockPgConnect, query: mockPgQuery, _ending: false };
jest.mock('pg', () => ({ Client: jest.fn(() => mockPgClient) }));

const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

const { handler } = require("../lambda_code/analyzePreferences.js");

describe("analyzePreferences Lambda", () => {
    const mockEnv = {
        AWS_REGION: 'us-east-1', DB_HOST: 'h', DB_PORT: '5432', DB_NAME: 'n',
        DB_USERNAME: 'u', DB_PASSWORD_SECRET_ARN: 'arn',
        ANALYSIS_BUCKET_NAME: 'test-bucket', REPORT_TOPIC_ARN: 'arn:test-topic',
    };

    beforeEach(() => {
        jest.clearAllMocks();
        consoleLogSpy.mockClear();
        consoleErrorSpy.mockClear();
        mockPgClient._ending = false;
        Object.assign(process.env, mockEnv);

        mockSecretsManagerSend.mockResolvedValue({ SecretString: JSON.stringify({ password: 'p' }) });
        mockPgConnect.mockResolvedValue(undefined);
        mockPgQuery.mockResolvedValue({ rows: [] });
        mockS3Send.mockResolvedValue({});
        mockSNSSend.mockResolvedValue({});

        jest.spyOn(Date, 'now').mockReturnValue(1678886400000);
        jest.spyOn(global, 'Date').mockImplementation((...args) => args.length ? new Date(...args) : new Date(1678886400000));
    });

    afterAll(() => {
        consoleLogSpy.mockRestore();
        consoleErrorSpy.mockRestore();
        jest.restoreAllMocks();
    });

    it("Debe analizar preferencias, guardar en S3 y publicar en SNS", async () => {
        const event = { detail: { customerId: "cust-A", preferences: {}, items: [] } };
    
        const tenOrders = Array(10).fill(null).map((_, i) => ({
            order_id: `o${i}`, customer_id: 'cust-A', items: `[{"productId":"P${i}"}]`, total_amount: 10 + i, preferences: '{}', order_date: new Date().toISOString()
        }));
        mockPgQuery.mockResolvedValueOnce({ rows: tenOrders });

        const result = await handler(event);

        expect(result.statusCode).toBe(200);
        expect(mockSecretsManagerSend).toHaveBeenCalledTimes(1);
        expect(mockPgConnect).toHaveBeenCalledTimes(1);
        expect(mockPgQuery).toHaveBeenCalledTimes(1);
        expect(mockS3Send).toHaveBeenCalledTimes(1);
        expect(mockSNSSend).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).not.toHaveBeenCalled();
    });

    it("Debe retornar 204 si no se encuentra detalle del evento", async () => {
        const result = await handler({});

        expect(result.statusCode).toBe(204);
        expect(mockSecretsManagerSend).not.toHaveBeenCalled();
        expect(consoleErrorSpy).not.toHaveBeenCalled();
    });

    it("Debe retornar un error si la conexión a la DB falla", async () => {
        const event = { detail: { customerId: "cust-B", preferences: {}, items: [] } };
        mockPgConnect.mockRejectedValueOnce(new Error("Error de conexión a DB"));

        await expect(handler(event)).rejects.toThrow("Error de conexión a DB");
        expect(mockPgConnect).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).toHaveBeenCalled();
    });

    it("Debe retornar un error si falla el guardado en S3", async () => {
        const event = { detail: { customerId: "cust-C", preferences: {}, items: [] } };
        mockS3Send.mockRejectedValueOnce(new Error("Error de carga en S3"));

        await expect(handler(event)).rejects.toThrow("Error de carga en S3");
        expect(mockS3Send).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).toHaveBeenCalled();
    });
});