const request = require('supertest');
const app = require('./app');

let server;

beforeAll(() => { server = app.listen(0); });
afterAll(() => server.close());

describe('GET /health', () => {
  it('returns 200 with healthy status', async () => {
    const res = await request(server).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('Healthy');
    expect(res.body.environment).toBeDefined();
  });
});

describe('GET /status', () => {
  it('returns 200 with running status', async () => {
    const res = await request(server).get('/status');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('Application is running smoothly!');
    expect(res.body.environment).toBeDefined();
  });
});

describe('POST /process', () => {
  it('processes valid data', async () => {
    const res = await request(server)
      .post('/process')
      .send({ data: 'hello' });
    expect(res.statusCode).toBe(200);
    expect(res.body.processed).toBe(true);
    expect(res.body.receivedData).toBe('hello');
  });

  it('returns 400 when data is missing', async () => {
    const res = await request(server).post('/process').send({});
    expect(res.statusCode).toBe(400);
  });
});