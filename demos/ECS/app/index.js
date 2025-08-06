const express = require('express');
const os = require('os');
const app = express();
const port = 3000;

// Middleware to log requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path} from ${req.ip}`);
  next();
});

// Serve static files (for our CSS)
app.use(express.static('public'));

// Main page with interactive features
app.get('/', (req, res) => {
  const uptime = process.uptime();
  const uptimeFormatted = `${Math.floor(uptime / 3600)}h ${Math.floor((uptime % 3600) / 60)}m ${Math.floor(uptime % 60)}s`;
  
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>🚀 ECS Fargate Demo</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                margin: 0;
                padding: 20px;
                min-height: 100vh;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
            }
            .container {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 20px;
                padding: 40px;
                text-align: center;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                max-width: 600px;
                width: 100%;
            }
            h1 {
                font-size: 3em;
                margin-bottom: 20px;
                text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
            }
            .stats {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
                gap: 20px;
                margin: 30px 0;
            }
            .stat-card {
                background: rgba(255, 255, 255, 0.2);
                padding: 20px;
                border-radius: 15px;
                border: 1px solid rgba(255, 255, 255, 0.3);
            }
            .stat-value {
                font-size: 1.5em;
                font-weight: bold;
                margin-bottom: 5px;
            }
            .stat-label {
                font-size: 0.9em;
                opacity: 0.8;
            }
            .button {
                background: #ff6b6b;
                color: white;
                border: none;
                padding: 15px 30px;
                border-radius: 25px;
                font-size: 1.1em;
                cursor: pointer;
                margin: 10px;
                transition: all 0.3s ease;
                text-decoration: none;
                display: inline-block;
            }
            .button:hover {
                background: #ff5252;
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
            }
            .emoji {
                font-size: 2em;
                margin: 0 10px;
            }
            @keyframes pulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.05); }
                100% { transform: scale(1); }
            }
            .pulse {
                animation: pulse 2s infinite;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1 class="pulse">🚀 Welcome to ECS Fargate!</h1>
            <p>Your containerized Node.js app is running smoothly in the cloud!</p>
            
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-value">⏱️ ${uptimeFormatted}</div>
                    <div class="stat-label">Uptime</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">🏠 ${os.hostname()}</div>
                    <div class="stat-label">Container ID</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">🐳 Fargate</div>
                    <div class="stat-label">Platform</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">🟢 Healthy</div>
                    <div class="stat-label">Status</div>
                </div>
            </div>
            
            <div>
                <a href="/health" class="button">🏥 Health Check</a>
                <a href="/info" class="button">ℹ️ System Info</a>
                <a href="/api/random" class="button">🎲 Random Fact</a>
            </div>
            
            <p style="margin-top: 30px; opacity: 0.8;">
                <span class="emoji">☁️</span>
                Powered by AWS ECS Fargate
                <span class="emoji">⚡</span>
            </p>
        </div>
        
        <script>
            // Auto-refresh every 30 seconds to show updated uptime
            setTimeout(() => {
                window.location.reload();
            }, 30000);
        </script>
    </body>
    </html>
  `);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.version,
    platform: process.platform
  });
});

// System information endpoint
app.get('/info', (req, res) => {
  res.json({
    hostname: os.hostname(),
    platform: os.platform(),
    architecture: os.arch(),
    cpus: os.cpus().length,
    memory: {
      total: Math.round(os.totalmem() / 1024 / 1024) + ' MB',
      free: Math.round(os.freemem() / 1024 / 1024) + ' MB'
    },
    uptime: os.uptime(),
    nodeVersion: process.version,
    environment: process.env.NODE_ENV || 'development'
  });
});

// Fun random facts API
app.get('/api/random', (req, res) => {
  const facts = [
    "🐳 Docker containers share the host OS kernel, making them more efficient than VMs!",
    "☁️ AWS Fargate automatically manages the underlying infrastructure for your containers.",
    "🚀 ECS can automatically scale your application based on CPU and memory usage.",
    "🔒 Each ECS task gets its own isolated network interface and security groups.",
    "⚡ Fargate tasks can start in under 30 seconds!",
    "🌍 This container could be running in any AWS region around the world.",
    "📊 ECS integrates seamlessly with CloudWatch for monitoring and logging.",
    "🔄 You can deploy new versions with zero downtime using rolling updates.",
    "💰 With Fargate, you only pay for the compute resources your containers actually use.",
    "🛡️ ECS tasks can assume IAM roles for secure access to other AWS services."
  ];
  
  const randomFact = facts[Math.floor(Math.random() * facts.length)];
  res.json({
    fact: randomFact,
    timestamp: new Date().toISOString(),
    container: os.hostname()
  });
});

// 404 handler with style
app.use((req, res) => {
  res.status(404).send(`
    <html>
    <head><title>404 - Not Found</title></head>
    <body style="font-family: Arial; text-align: center; padding: 50px; background: #f0f0f0;">
      <h1>🤔 Oops! Page not found</h1>
      <p>The page you're looking for doesn't exist.</p>
      <a href="/" style="color: #667eea; text-decoration: none;">← Go back home</a>
    </body>
    </html>
  `);
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server is running on port ${port}`);
  console.log(`📊 Health check available at /health`);
  console.log(`ℹ️  System info available at /info`);
  console.log(`🎲 Random facts available at /api/random`);
});
