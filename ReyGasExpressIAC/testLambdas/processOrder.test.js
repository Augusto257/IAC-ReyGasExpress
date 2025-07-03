const mockSecretsManagerSend = jest.fn();
jest.mock('@aws-sdk/client-secrets-manager', () => ({
    SecretsManagerClient: jest.fn(() => ({ send: mockSecretsManagerSend })),
    GetSecretValueCommand: jest.fn((input) => input),
}));

const mockEventBridgeSend = jest.fn();
jest.mock('@aws-sdk/client-eventbridge', () => ({
    EventBridgeClient: jest.fn(() => ({ send: mockEventBridgeSend })),
    PutEventsCommand: jest.fn((input) => input),
}));

const mockPgConnect = jest.fn();
const mockPgQuery = jest.fn();
const mockPgClient = {
    connect: mockPgConnect,
    query: mockPgQuery,
    _ending: false,
};
jest.mock('pg', () => ({
    Client: jest.fn(() => mockPgClient),
}));

const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

const { handler } = require("../lambda_code/processOrder.js");

describe("processOrder Lambda", () => {
    const mockEnv = {
        AWS_REGION: 'us-east-1', DB_HOST: 'h', DB_PORT: '5432', DB_NAME: 'n',
        DB_USERNAME: 'u', DB_PASSWORD_SECRET_ARN: 'arn', EVENT_BUS_NAME: 'eb',
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
        mockEventBridgeSend.mockResolvedValue({});
    });

    afterAll(() => {
        consoleLogSpy.mockRestore();
        consoleErrorSpy.mockRestore();
    });

    it("Se debe procesar, guardar y pubicar un pedido", async () => {
        // Arrange
        const event = { Records: [{ body: JSON.stringify({ orderId: "o1", customerId: "c1", items: [], totalAmount: 10 }) }] };

        // Act
        const result = await handler(event);

        // Assert
        expect(result.statusCode).toBe(200);
        expect(mockSecretsManagerSend).toHaveBeenCalledTimes(1);
        expect(mockPgConnect).toHaveBeenCalledTimes(1);
        expect(mockPgQuery).toHaveBeenCalledTimes(2);
        expect(mockPgQuery).toHaveBeenCalledWith(expect.stringContaining('CREATE TABLE IF NOT EXISTS orders'));
        expect(mockPgQuery).toHaveBeenCalledWith(expect.stringContaining('INSERT INTO orders'), expect.any(Array));
        expect(mockEventBridgeSend).toHaveBeenCalledTimes(1);
        expect(mockEventBridgeSend).toHaveBeenCalledWith(expect.objectContaining({ Entries: expect.arrayContaining([expect.objectContaining({ DetailType: "Order Processed" })]) }));
        expect(consoleErrorSpy).not.toHaveBeenCalled();
    });

    it("Retorna error si Secrets Manager falla", async () => {
        // Arrange
        const event = { Records: [{ body: JSON.stringify({ orderId: "o2", customerId: "c2", items: [], totalAmount: 20 }) }] };
        mockSecretsManagerSend.mockRejectedValueOnce(new Error("SM Error"));

        // Act & Assert
        await expect(handler(event)).rejects.toThrow("SM Error");
        expect(mockSecretsManagerSend).toHaveBeenCalledTimes(1);
        expect(mockPgConnect).not.toHaveBeenCalled();
        expect(mockEventBridgeSend).not.toHaveBeenCalled();
        expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('Error al obtener credenciales de Secrets Manager:'));
    });

    it("Retorna un error si la conexión con la base de datos falla", async () => {
        // Arrange
        const event = { Records: [{ body: JSON.stringify({ orderId: "o3", customerId: "c3", items: [], totalAmount: 30 }) }] };
        mockPgConnect.mockRejectedValueOnce(new Error("DB Connect Error"));

        // Act & Assert
        await expect(handler(event)).rejects.toThrow("DB Connect Error");
        expect(mockSecretsManagerSend).toHaveBeenCalledTimes(1);
        expect(mockPgConnect).toHaveBeenCalledTimes(1);
        expect(mockPgQuery).not.toHaveBeenCalled();
        expect(mockEventBridgeSend).not.toHaveBeenCalled();
        expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('Error al conectar a la base de datos PostgreSQL:'));
    });

    it("Retorna un error si la inserción en la base de datos falla", async () => {
        // Arrange
        const event = { Records: [{ body: JSON.stringify({ orderId: "o4", customerId: "c4", items: [], totalAmount: 40 }) }] };
        mockPgQuery.mockResolvedValueOnce({});
        mockPgQuery.mockRejectedValueOnce(new Error("DB Insert Error"));

        // Act & Assert
        await expect(handler(event)).rejects.toThrow("DB Insert Error");
        expect(mockSecretsManagerSend).toHaveBeenCalledTimes(1);
        expect(mockPgConnect).toHaveBeenCalledTimes(1);
        expect(mockPgQuery).toHaveBeenCalledTimes(2);
        expect(mockEventBridgeSend).not.toHaveBeenCalled();
        expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('Error en processOrder:'));
    });
});