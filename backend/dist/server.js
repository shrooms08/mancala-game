"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const body_parser_1 = __importDefault(require("body-parser"));
const dotenv_1 = require("dotenv");
const honeycomb_1 = require("./lib/honeycomb");
const logger_1 = require("./lib/logger");
(0, dotenv_1.config)();
logger_1.logContext.server('Starting Mancala backend server');
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(body_parser_1.default.json());
// Add request logging middleware
app.use(logger_1.requestLogger);
let isBootstrapped = false;
async function bootstrap() {
    if (isBootstrapped) {
        logger_1.logContext.server('Server already bootstrapped, skipping initialization');
        return;
    }
    logger_1.logContext.server('Starting Honeycomb project bootstrap');
    try {
        const ctx = await logger_1.logTiming.time('Honeycomb context initialization', async () => (0, honeycomb_1.initContext)(), 'server');
        logger_1.logContext.server('Honeycomb context initialized successfully');
        const project = await logger_1.logTiming.time('Project creation/verification', async () => (0, honeycomb_1.createProjectIfMissing)(ctx), 'server');
        logger_1.logContext.server('Project creation/verification completed', { project });
        await logger_1.logTiming.time('Profiles tree verification', async () => (0, honeycomb_1.ensureProfilesTree)(ctx, project), 'server');
        logger_1.logContext.server('Profiles tree verification completed');
        isBootstrapped = true;
        logger_1.logContext.server('Honeycomb project bootstrap completed successfully', { project });
    }
    catch (error) {
        logger_1.logContext.error('Bootstrap failed', error, 'server');
        throw error;
    }
}
// Health check endpoint
app.get('/health', (_req, res) => {
    logger_1.logContext.api('Health check requested');
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
    logger_1.logContext.api('Manual initialization requested');
    try {
        await bootstrap();
        logger_1.logContext.api('Manual initialization completed successfully');
        res.json({
            ok: true,
            project: process.env.PROJECT_ADDRESS,
            message: 'Project initialized successfully'
        });
    }
    catch (e) {
        logger_1.logContext.error('Manual initialization failed', e, 'api');
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
        (0, logger_1.setLogLevel)(level);
        res.json({
            success: true,
            message: `Log level changed to ${level}`,
            currentLevel: level
        });
    }
    catch (error) {
        logger_1.logContext.error('Failed to change log level', error, 'api');
        res.status(500).json({
            error: 'Failed to change log level',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Logging statistics endpoint
app.get('/logs/stats', (_req, res) => {
    try {
        const stats = (0, logger_1.logStats)();
        res.json({
            success: true,
            stats
        });
    }
    catch (error) {
        logger_1.logContext.error('Failed to get log statistics', error, 'api');
        res.status(500).json({
            error: 'Failed to get log statistics',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// Import and register route modules
const users_1 = __importDefault(require("./routes/users"));
const game_1 = __importDefault(require("./routes/game"));
app.use('/users', users_1.default);
app.use('/game', game_1.default);
logger_1.logContext.server('Route modules registered', {
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
    logger_1.logContext.server(`Server listening on port ${PORT}`);
    try {
        logger_1.logContext.server('Attempting automatic bootstrap on startup');
        await bootstrap();
        logger_1.logContext.server('Automatic bootstrap completed successfully');
    }
    catch (e) {
        logger_1.logContext.error('Automatic bootstrap failed - server will start but may not be fully functional', e, 'server');
        logger_1.logContext.warn('Use POST /init endpoint to manually initialize the project', null, 'server');
        // Provide helpful guidance for EdgeClient issues
        if (e instanceof Error && e.message.includes('Edge client')) {
            logger_1.logContext.warn('HONEYCOMB INTEGRATION ISSUE DETECTED:', null, 'server');
            logger_1.logContext.warn('The @honeycomb-protocol/edge-client package may not be properly installed or configured.', null, 'server');
            logger_1.logContext.warn('To fix this:', null, 'server');
            logger_1.logContext.warn('1. Check that @honeycomb-protocol/edge-client is installed: npm list @honeycomb-protocol/edge-client', null, 'server');
            logger_1.logContext.warn('2. Verify the package version and compatibility', null, 'server');
            logger_1.logContext.warn('3. Check the Honeycomb Protocol documentation for correct usage', null, 'server');
            logger_1.logContext.warn('4. Ensure your .env file has valid HONEYCOMB_EDGE and HONEYCOMB_RPC URLs', null, 'server');
            logger_1.logContext.warn('The server will continue running but blockchain features will not work.', null, 'server');
        }
    }
    logger_1.logContext.server('Server startup sequence completed', {
        port: PORT,
        bootstrapped: isBootstrapped,
        project: process.env.PROJECT_ADDRESS || null
    });
});
// Graceful shutdown handling
process.on('SIGTERM', () => {
    logger_1.logContext.server('SIGTERM received, shutting down gracefully');
    process.exit(0);
});
process.on('SIGINT', () => {
    logger_1.logContext.server('SIGINT received, shutting down gracefully');
    process.exit(0);
});
process.on('uncaughtException', (error) => {
    logger_1.logContext.error('Uncaught exception', error, 'server');
    process.exit(1);
});
process.on('unhandledRejection', (reason, promise) => {
    logger_1.logContext.error('Unhandled promise rejection', { reason, promise }, 'server');
    process.exit(1);
});
