const mockSESSend = jest.fn();
jest.mock('@aws-sdk/client-ses', () => ({ SESClient: jest.fn(() => ({ send: mockSESSend })), SendEmailCommand: jest.fn(i => i) }));

const mockS3Send = jest.fn();
jest.mock('@aws-sdk/client-s3', () => ({ S3Client: jest.fn(() => ({ send: mockS3Send })), GetObjectCommand: jest.fn(i => i) }));

const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

const { handler } = require("../lambda_code/sendEmailReport.js");

describe("sendEmailReport Lambda", () => {
    const env = { R_B: 'rb', F_E: 'f@e.com', T_E: 't@e.com' };
    const s3Body = { transformToString: jest.fn(() => Promise.resolve('<html>R</html>')) };

    beforeEach(() => {
        jest.clearAllMocks();
        consoleErrorSpy.mockClear();
        Object.assign(process.env, { REPORTS_BUCKET_NAME: env.R_B, FROM_EMAIL: env.F_E, TO_EMAIL: env.T_E, AWS_REGION: 'us-east-1' });
        mockS3Send.mockResolvedValue({ Body: s3Body });
        mockSESSend.mockResolvedValue({ MessageId: 'mid' });
        jest.spyOn(global, 'Date').mockImplementation(() => new Date('2023-01-01T10:00:00Z'));
    });

    afterAll(() => { consoleErrorSpy.mockRestore(); jest.restoreAllMocks(); });

    it("Debe enviar el email correctamente", async () => {
        const e = { Records: [{ Sns: { Message: JSON.stringify({ customerId: "c1", reportLocation: `s3://${env.R_B}/r1.html`, reportType: 'p', generatedAt: '2023-01-01T10:00:00Z' }) } }] };
        const r = await handler(e);
        expect(r.statusCode).toBe(200);
        expect(mockS3Send).toHaveBeenCalledTimes(1);
        expect(mockSESSend).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).not.toHaveBeenCalled();
    });

    it("Debe retornar error si falla S3 GetObject", async () => {
        const e = { Records: [{ Sns: { Message: JSON.stringify({ customerId: "c2", reportLocation: `s3://${env.R_B}/r2.html`, reportType: 'p', generatedAt: '2023-01-01T10:00:00Z' }) } }] };
        mockS3Send.mockRejectedValueOnce(new Error("S3 Err"));
        await expect(handler(e)).rejects.toThrow("S3 Err");
        expect(mockS3Send).toHaveBeenCalledTimes(1);
        expect(mockSESSend).not.toHaveBeenCalled();
        expect(consoleErrorSpy).toHaveBeenCalled();
    });

    it("Debe manejar errores SES recuperables (200)", async () => {
        const e = { Records: [{ Sns: { Message: JSON.stringify({ customerId: "c3", reportLocation: `s3://${env.R_B}/r3.html`, reportType: 'p', generatedAt: '2023-01-01T10:00:00Z' }) } }] };
        const err = new Error("SES Rec"); err.Code = 'MessageRejected';
        mockSESSend.mockRejectedValueOnce(err);
        const r = await handler(e);
        expect(r.statusCode).toBe(200);
        expect(r.message).toBe('Email handling completed with warnings');
        expect(mockSESSend).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).toHaveBeenCalled();
    });

    it("Debe retornar error si falla SES no recuperable", async () => {
        const e = { Records: [{ Sns: { Message: JSON.stringify({ customerId: "c4", reportLocation: `s3://${env.R_B}/r4.html`, reportType: 'p', generatedAt: '2023-01-01T10:00:00Z' }) } }] };
        const err = new Error("SES Fatal"); err.Code = 'Other';
        mockSESSend.mockRejectedValueOnce(err);
        await expect(handler(e)).rejects.toThrow("SES Fatal");
        expect(mockSESSend).toHaveBeenCalledTimes(1);
        expect(consoleErrorSpy).toHaveBeenCalled();
    });
});