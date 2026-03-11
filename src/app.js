const express = require('express');
const app = express();
app.use(express.json());
const PORT = process.env.PORT || 3000;

const log = (level, message, meta = {}) => {
  console.log(JSON.stringify({
    level,
    message,
    timestamp: new Date().toISOString(),
    ...meta
  }));
};

// Request logger middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    log('info', 'request', {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration_ms: Date.now() - start
    });
  });
  next();
});

app.get('/', (req, res)=>[
    res.send('Hello Welcome to Production-Ready DevOps Pipeline!')
])

app.get('/health', (req, res)=>{
    json_response = {
        status: 'Healthy',
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        timestamp: new Date().toISOString()
    }
    log('info', 'health check', json_response);
    res.status(200).json(json_response)
})

app.get('/status', (req, res)=>{
    json_response = {
        status: 'Application is running smoothly!',
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        timestamp: new Date().toISOString()
    }
    log('info', 'status check', json_response);
    res.status(200).json(json_response)
})

app.post('/process', (req, res)=>{
    const { data } = req.body;
    if (!data) {
        log('error', 'Data is required');
        return res.status(400).json({ error: 'Data is required' });
    }
    log('info', 'Data received', { data });
    res.status(200).json({ 
        message: 'Data processed successfully',
        receivedData: data,
        processed: true,
        environment: process.env.NODE_ENV || 'development',
        timestamp: new Date().toISOString()
    })
})

// 404 handler
app.use((req, res) => {
  log('warn', 'route not found', { path: req.path });
  res.status(404).json({ error: 'Not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  log('error', 'unhandled error', { error: err.message });
  res.status(500).json({ error: 'Internal server error' });
});

if (require.main === module) {
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Server is running on port ${PORT}`);
    })
}
module.exports = app;