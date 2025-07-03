const mockS3Send = jest.fn();
jest.mock('@aws-sdk/client-s3', () => ({ S3Client: jest.fn(() => ({ send: mockS3Send })), GetObjectCommand: jest.fn(i => i), PutObjectCommand: jest.fn(i => i) }));

const mockSNSSend = jest.fn();
jest.mock('@aws-sdk/client-sns', () => ({ SNSClient: jest.fn(() => ({ send: mockSNSSend })), PublishCommand: jest.fn(i => i) }));

const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

const { handler } = require("../lambda_code/generateReport.js");

describe("generateReport Lambda", () => {
    const mockEnv = {
        ANALYSIS_BUCKET_NAME: 'mock-analysis-bucket',
        REPORTS_BUCKET_NAME: 'mock-reports-bucket',
        EMAIL_TOPIC_ARN: 'arn:test-email-topic',
    };

    const minimalAnalysisData = {
        customerId: "test-customer", analysisDate: "", totalOrders: 0,
        preferences: { favoriteCategories: [], averageOrderValue: 0 },
        recommendations: { suggestedItems: [] }, trends: {}
    };
    const mockS3Body = { transformToString: jest.fn(() => Promise.resolve(JSON.stringify(minimalAnalysisData))) };

    beforeEach(() => {
        jest.clearAllMocks();
        consoleErrorSpy.mockClear();
        Object.assign(process.env, mockEnv);

        mockS3Send.mockImplementation((command) => {
            if (command.constructor.name === 'GetObjectCommand') return { Body: mockS3Body };
            return {};
        });
        mockSNSSend.mockResolvedValue({});

        jest.spyOn(Date, 'now').mockReturnValue(1678886400000);
        jest.spyOn(global, 'Date').mockImplementation((...args) => args.length ? new Date(...args) : new Date(1678886400000));
    });

    afterAll(() => {
        consoleErrorSpy.mockRestore();
        jest.restoreAllMocks();
    });

    it("Debe generar reporte, guardar en S3 y notificar por SNS", async () => {
        const event = { Records: [{ Sns: { Message: JSON.stringify({ customerId: "test-cust", s3Location: `s3://${mockEnv.ANALYSIS_BUCKET_NAME}/key.json` }) } }] };
        const result = await handler(event);

        expect(result.statusCode).toBe(200);
        expect(mockS3Send).toHaveBeenCalledTimes(2); 
        expect(mockSNSSend).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).not.toHaveBeenCalled();
    });

    it("Debe retornar error si falla lectura de S3", async () => {
        const event = { Records: [{ Sns: { Message: JSON.stringify({ customerId: "fail-get", s3Location: `s3://${mockEnv.ANALYSIS_BUCKET_NAME}/fail.json` }) } }] };
        mockS3Send.mockRejectedValueOnce(new Error("Error S3 Get"));

        await expect(handler(event)).rejects.toThrow("Error S3 Get");
        expect(mockS3Send).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).toHaveBeenCalled();
    });

    it("Debe retornar error si falla guardado en S3", async () => {
        const event = { Records: [{ Sns: { Message: JSON.stringify({ customerId: "fail-put", s3Location: `s3://${mockEnv.ANALYSIS_BUCKET_NAME}/ok.json` }) } }] };
        mockS3Send.mockImplementationOnce(() => ({ Body: mockS3Body }));
        mockS3Send.mockRejectedValueOnce(new Error("Error S3 Put"));

        await expect(handler(event)).rejects.toThrow("Error S3 Put");
        expect(mockS3Send).toHaveBeenCalledTimes(2);
        expect(consoleErrorSpy).toHaveBeenCalled();
    });

    it("Debe retornar error si falla publicación SNS", async () => {
        const event = { Records: [{ Sns: { Message: JSON.stringify({ customerId: "fail-sns", s3Location: `s3://${mockEnv.ANALYSIS_BUCKET_NAME}/ok.json` }) } }] };
        mockSNSSend.mockRejectedValueOnce(new Error("Error SNS Publish"));

        await expect(handler(event)).rejects.toThrow("Error SNS Publish");
        expect(mockSNSSend).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).toHaveBeenCalled();
    });
});