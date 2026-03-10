const express = require('express');
const app = express();
app.use(express.json());
const PORT = process.env.PORT || 3000;

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
    console.log(json_response)
    res.status(200).json(json_response)
})

app.get('/status', (req, res)=>{
    json_response = {
        status: 'Application is running smoothly!',
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        timestamp: new Date().toISOString()
    }
    console.log(json_response)
    res.status(200).json(json_response)
})

app.post('/process', (req, res)=>{
    const { data } = req.body;
    if (!data) {
        console.log(data)
        return res.status(400).json({ error: 'Data is required' });
    }
    console.log(data)
    res.status(200).json({ 
        message: 'Data processed successfully',
        receivedData: data,
        processed: true,
        environment: process.env.NODE_ENV || 'development',
        timestamp: new Date().toISOString()
    })
})

if (require.main === module) {
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Server is running on port ${PORT}`);
    })
}
module.exports = app;