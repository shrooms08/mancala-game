import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { config as env } from 'dotenv';
import { initContext, createProjectIfMissing, ensureProfilesTree } from './lib/honeycomb';
import { logContext, requestLogger, logTiming, setLogLevel, logStats } from './lib/logger';

env();
logContext.server('Starting Mancala backend server');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Add request logging middleware
app.use(requestLogger);

let isBootstrapped = false;

async function bootstrap() {
  if (isBootstrapped) {
    logContext.server('Server already bootstrapped, skipping initialization');
    return;
  }
  
  logContext.server('Starting Honeycomb project bootstrap');
  
  try {
    const ctx = await logTiming.time('Honeycomb context initialization', 
      async () => initContext(), 'server');
    logContext.server('Honeycomb context initialized successfully');
    
    const project = await logTiming.time('Project creation/verification', 
      async () => createProjectIfMissing(ctx), 'server');
    logContext.server('Project creation/verification completed', { project });
    
    await logTiming.time('Profiles tree verification', 
      async () => ensureProfilesTree(ctx, project), 'server');
    logContext.server('Profiles tree verification completed');
    
    isBootstrapped = true;
    logContext.server('Honeycomb project bootstrap completed successfully', { project });
  } catch (error) {
    logContext.error('Bootstrap failed', error, 'server');
    throw error;
  }
}

// Health check endpoint
app.get('/health', (_req, res) => {
  logContext.api('Health check requested');
  res.json({ 
    ok: true, 
    timestamp: new Date().toISOString(),
    bootstrapped: isBootstrapped,
    project: process.env.PROJECT_ADDRESS || null,
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// Manual initialization endpoint
app.post('/init', async (_req, res) => {
  logContext.api('Manual initialization requested');
  
  try {
    await bootstrap();
    logContext.api('Manual initialization completed successfully');
    res.json({ 
      ok: true, 
      project: process.env.PROJECT_ADDRESS,
      message: 'Project initialized successfully'
    });
  } catch (e: any) {
    logContext.error('Manual initialization failed', e, 'api');
    res.status(500).json({ 
      error: e.message,
      details: process.env.NODE_ENV === 'development' ? e.stack : undefined
    });
  }
});

// Logging configuration endpoint
app.post('/logs/level', (req, res) => {
  const { level } = req.body;
  
  if (!level || !['debug', 'info', 'warn', 'error'].includes(level)) {
    return res.status(400).json({ 
      error: 'Invalid log level. Must be one of: debug, info, warn, error' 
    });
  }
  
  try {
    setLogLevel(level);
    res.json({ 
      success: true, 
      message: `Log level changed to ${level}`,
      currentLevel: level 
    });
  } catch (error) {
    logContext.error('Failed to change log level', error, 'api');
    res.status(500).json({ 
      error: 'Failed to change log level',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Logging statistics endpoint
app.get('/logs/stats', (_req, res) => {
  try {
    const stats = logStats();
    res.json({ 
      success: true, 
      stats 
    });
  } catch (error) {
    logContext.error('Failed to get log statistics', error, 'api');
    res.status(500).json({ 
      error: 'Failed to get log statistics',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Import and register route modules
import usersRouter from './routes/users';
import gameRouter from './routes/game';

app.use('/users', usersRouter);
app.use('/game', gameRouter);

logContext.server('Route modules registered', { 
  routes: [
    '/users', 
    '/game', 
    '/health', 
    '/init',
    '/logs/level',
    '/logs/stats'
  ] 
});

const PORT = process.env.PORT || 8080;

app.listen(PORT, async () => {
  logContext.server(`Server listening on port ${PORT}`);
  
  try {
    logContext.server('Attempting automatic bootstrap on startup');
    await bootstrap();
    logContext.server('Automatic bootstrap completed successfully');
  } catch (e) {
    logContext.error('Automatic bootstrap failed - server will start but may not be fully functional', e, 'server');
    logContext.warn('Use POST /init endpoint to manually initialize the project', null, 'server');
    
    // Provide helpful guidance for EdgeClient issues
    if (e instanceof Error && e.message.includes('Edge client')) {
      logContext.warn('HONEYCOMB INTEGRATION ISSUE DETECTED:', null, 'server');
      logContext.warn('The @honeycomb-protocol/edge-client package may not be properly installed or configured.', null, 'server');
      logContext.warn('To fix this:', null, 'server');
      logContext.warn('1. Check that @honeycomb-protocol/edge-client is installed: npm list @honeycomb-protocol/edge-client', null, 'server');
      logContext.warn('2. Verify the package version and compatibility', null, 'server');
      logContext.warn('3. Check the Honeycomb Protocol documentation for correct usage', null, 'server');
      logContext.warn('4. Ensure your .env file has valid HONEYCOMB_EDGE and HONEYCOMB_RPC URLs', null, 'server');
      logContext.warn('The server will continue running but blockchain features will not work.', null, 'server');
    }
  }
  
  logContext.server('Server startup sequence completed', { 
    port: PORT,
    bootstrapped: isBootstrapped,
    project: process.env.PROJECT_ADDRESS || null
  });
});

// Graceful shutdown handling
process.on('SIGTERM', () => {
  logContext.server('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logContext.server('SIGINT received, shutting down gracefully');
  process.exit(0);
});

process.on('uncaughtException', (error) => {
  logContext.error('Uncaught exception', error, 'server');
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logContext.error('Unhandled promise rejection', { reason, promise }, 'server');
  process.exit(1);
});
