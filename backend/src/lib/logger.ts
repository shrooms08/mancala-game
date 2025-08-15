import pino from 'pino';

// Create a centralized logger instance
export const logger = pino({
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
export const logContext = {
  honeycomb: (msg: string, data?: any) => logger.info({ context: 'honeycomb', ...data }, msg),
  server: (msg: string, data?: any) => logger.info({ context: 'server', ...data }, msg),
  api: (msg: string, data?: any) => logger.info({ context: 'api', ...data }, msg),
  game: (msg: string, data?: any) => logger.info({ context: 'game', ...data }, msg),
  state: (msg: string, data?: any) => logger.info({ context: 'state', ...data }, msg),
  error: (msg: string, error?: any, context?: string) => logger.error({ 
    context: context || 'general', 
    error: error?.message || error,
    stack: error?.stack 
  }, msg),
  warn: (msg: string, data?: any, context?: string) => logger.warn({ 
    context: context || 'general', 
    ...data 
  }, msg),
  debug: (msg: string, data?: any, context?: string) => logger.debug({ 
    context: context || 'general', 
    ...data 
  }, msg)
};

// Performance timing utility
export const logTiming = {
  start: (operation: string, context?: string) => {
    const startTime = Date.now();
    logContext.debug(`Starting operation: ${operation}`, { operation, startTime }, context);
    return startTime;
  },
  
  end: (operation: string, startTime: number, context?: string, additionalData?: any) => {
    const duration = Date.now() - startTime;
    logContext.debug(`Completed operation: ${operation}`, { 
      operation, 
      duration: `${duration}ms`,
      ...additionalData 
    }, context);
    return duration;
  },
  
  async time<T>(operation: string, fn: () => Promise<T>, context?: string): Promise<T> {
    const startTime = this.start(operation, context);
    try {
      const result = await fn();
      this.end(operation, startTime, context, { success: true });
      return result;
    } catch (error) {
      this.end(operation, startTime, context, { 
        success: false, 
        error: error instanceof Error ? error.message : String(error) 
      });
      throw error;
    }
  }
};

// Request ID generation and tracking
export const generateRequestId = (): string => {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};

// Request logging middleware with enhanced details
export const requestLogger = (req: any, res: any, next: any) => {
  const start = Date.now();
  const requestId = generateRequestId();
  
  // Add request ID to request object for tracking
  req.requestId = requestId;
  
  logger.info({
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
    logger.info({
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

// Enhanced error logging with context
export const logError = (error: any, context: string, additionalData?: any) => {
  logContext.error('An error occurred', error, context);
  
  // Log additional context if available
  if (additionalData) {
    logContext.debug('Error context data', additionalData, context);
  }
  
  // Log error details for debugging
  if (error?.stack) {
    logContext.debug('Error stack trace', { stack: error.stack }, context);
  }
};

// Log level utility
export const setLogLevel = (level: string) => {
  logger.level = level;
  logContext.server(`Log level changed to: ${level}`);
};

// Log rotation and cleanup utility
export const logStats = () => {
  const stats = {
    timestamp: new Date().toISOString(),
    logLevel: logger.level,
    pid: process.pid,
    memory: process.memoryUsage(),
    uptime: process.uptime()
  };
  
  logContext.server('Logging system statistics', stats);
  return stats;
};
