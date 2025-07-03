const mockSend = jest.fn();
jest.mock('@aws-sdk/client-cloudwatch', () => ({
    CloudWatchClient: jest.fn(() => ({ send: mockSend })),
    PutMetricDataCommand: jest.fn((input) => input),
}));

const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

const { handler } = require("../lambda_code/registerOrder.js");
describe("registerOrder Lambda", () => {
    beforeEach(() => {
        mockSend.mockClear();
        consoleLogSpy.mockClear();
        consoleErrorSpy.mockClear();
        process.env.AWS_REGION = 'us-east-1';
    });

    afterAll(() => {
        consoleLogSpy.mockRestore();
        consoleErrorSpy.mockRestore();
    });

    it("Retorna status 200 para un pedido válido", async () => {
        // Arrange
        const event = {
            body: JSON.stringify({ customerId: "cust-1", items: [{ id: "item-1" }], totalAmount: 100 }),
        };
        mockSend.mockResolvedValue({});

        // Act
        const result = await handler(event);

        // Assert
        expect(result.statusCode).toBe(200);
        const body = JSON.parse(result.body);
        expect(body.message).toBe('Pedido recibido. Enviando para procesamiento.');
        expect(body.orderId).toMatch(/^order-/);
        expect(mockSend).toHaveBeenCalledTimes(1);
        expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('"level":"INFO"'));
        expect(consoleErrorSpy).not.toHaveBeenCalled();
    });

    it("Retorna status 400 por datos incompletos", async () => {
        // Arrange
        const event = {
            body: JSON.stringify({ items: [{ id: "item-2" }], totalAmount: 50 }),
        };
        mockSend.mockResolvedValue({});

        // Act
        const result = await handler(event);

        // Assert
        expect(result.statusCode).toBe(400);
        const body = JSON.parse(result.body);
        expect(body.message).toBe('Datos incompletos');
        expect(mockSend).toHaveBeenCalledTimes(2);
        expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('"level":"WARN"'));
        expect(consoleErrorSpy).not.toHaveBeenCalled();
    });

    it("Retorna status 500 para un body JSON no válido", async () => {
        // Arrange
        const event = { body: '{"customerId": "cust-3", "items":' };
        mockSend.mockResolvedValue({});

        // Act
        const result = await handler(event);

        // Assert
        expect(result.statusCode).toBe(500);
        const body = JSON.parse(result.body);
        expect(body.message).toBe('Error interno');
        expect(body.details).toContain('Unexpected');
        expect(mockSend).toHaveBeenCalledTimes(2);
        expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('"level":"ERROR"'));
    });

    it("Retorna status 500 si falla el envío de métricas de CloudWatch", async () => {
        // Arrange
        const event = {
            body: JSON.stringify({ customerId: "cust-4", items: [{ id: "item-4" }], totalAmount: 25 }),
        };
        const simulatedError = new Error("Simulated network error");
        mockSend.mockRejectedValueOnce(simulatedError);

        // Act
        const result = await handler(event);

        // Assert
        expect(result.statusCode).toBe(500);
        const body = JSON.parse(result.body);
        expect(body.message).toBe('Error interno');
        expect(body.details).toBe(simulatedError.message);
        expect(mockSend).toHaveBeenCalledTimes(2);
        expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('"level":"ERROR"'));
    });
});