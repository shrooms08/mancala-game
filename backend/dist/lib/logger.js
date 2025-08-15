"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.logStats = exports.setLogLevel = exports.logError = exports.requestLogger = exports.generateRequestId = exports.logTiming = exports.logContext = exports.logger = void 0;
const pino_1 = __importDefault(require("pino"));
// Create a centralized logger instance
exports.logger = (0, pino_1.default)({
    level: process.env.LOG_LEVEL || 'info',
    transport: {
        target: 'pino-pretty',
        options: {
            colorize: true,
            translateTime: 'SYS:standard',
            ignore: 'pid,hostname',
        }
    }
});
// Helper functions for different log contexts
exports.logContext = {
    honeycomb: (msg, data) => exports.logger.info({ context: 'honeycomb', ...data }, msg),
    server: (msg, data) => exports.logger.info({ context: 'server', ...data }, msg),
    api: (msg, data) => exports.logger.info({ context: 'api', ...data }, msg),
    game: (msg, data) => exports.logger.info({ context: 'game', ...data }, msg),
    state: (msg, data) => exports.logger.info({ context: 'state', ...data }, msg),
    error: (msg, error, context) => exports.logger.error({
        context: context || 'general',
        error: error?.message || error,
        stack: error?.stack
    }, msg),
    warn: (msg, data, context) => exports.logger.warn({
        context: context || 'general',
        ...data
    }, msg),
    debug: (msg, data, context) => exports.logger.debug({
        context: context || 'general',
        ...data
    }, msg)
};
// Performance timing utility
exports.logTiming = {
    start: (operation, context) => {
        const startTime = Date.now();
        exports.logContext.debug(`Starting operation: ${operation}`, { operation, startTime }, context);
        return startTime;
    },
    end: (operation, startTime, context, additionalData) => {
        const duration = Date.now() - startTime;
        exports.logContext.debug(`Completed operation: ${operation}`, {
            operation,
            duration: `${duration}ms`,
            ...additionalData
        }, context);
        return duration;
    },
    async time(operation, fn, context) {
        const startTime = this.start(operation, context);
        try {
            const result = await fn();
            this.end(operation, startTime, context, { success: true });
            return result;
        }
        catch (error) {
            this.end(operation, startTime, context, {
                success: false,
                error: error instanceof Error ? error.message : String(error)
            });
            throw error;
        }
    }
};
// Request ID generation and tracking
const generateRequestId = () => {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};
exports.generateRequestId = generateRequestId;
// Request logging middleware with enhanced details
const requestLogger = (req, res, next) => {
    const start = Date.now();
    const requestId = (0, exports.generateRequestId)();
    // Add request ID to request object for tracking
    req.requestId = requestId;
    exports.logger.info({
        context: 'http',
        requestId,
        method: req.method,
        url: req.url,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        headers: {
            'content-type': req.get('Content-Type'),
            'content-length': req.get('Content-Length'),
            'accept': req.get('Accept')
        }
    }, `Incoming ${req.method} ${req.url}`);
    res.on('finish', () => {
        const duration = Date.now() - start;
        exports.logger.info({
            context: 'http',
            requestId,
            method: req.method,
            url: req.url,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            responseHeaders: {
                'content-type': res.get('Content-Type'),
                'content-length': res.get('Content-Length')
            }
        }, `Completed ${req.method} ${req.url} - ${res.statusCode} (${duration}ms)`);
    });
    next();
};
exports.requestLogger = requestLogger;
// Enhanced error logging with context
const logError = (error, context, additionalData) => {
    exports.logContext.error('An error occurred', error, context);
    // Log additional context if available
    if (additionalData) {
        exports.logContext.debug('Error context data', additionalData, context);
    }
    // Log error details for debugging
    if (error?.stack) {
        exports.logContext.debug('Error stack trace', { stack: error.stack }, context);
    }
};
exports.logError = logError;
// Log level utility
const setLogLevel = (level) => {
    exports.logger.level = level;
    exports.logContext.server(`Log level changed to: ${level}`);
};
exports.setLogLevel = setLogLevel;
// Log rotation and cleanup utility
const logStats = () => {
    const stats = {
        timestamp: new Date().toISOString(),
        logLevel: exports.logger.level,
        pid: process.pid,
        memory: process.memoryUsage(),
        uptime: process.uptime()
    };
    exports.logContext.server('Logging system statistics', stats);
    return stats;
};
exports.logStats = logStats;
