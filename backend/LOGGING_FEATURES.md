# Comprehensive Logging Features

This document outlines all the logging capabilities implemented across the Mancala backend project.

## 🎯 Centralized Logging System

### Core Logger (`src/lib/logger.ts`)
- **Structured JSON logging** with Pino
- **Colorized console output** with pino-pretty
- **Configurable log levels** via environment variables
- **Context-aware logging** for different parts of the system

### Log Contexts
Each log message is tagged with a context for easy filtering and analysis:

- **`honeycomb`** - Blockchain operations and Honeycomb Protocol interactions
- **`server`** - Server lifecycle, bootstrap, and startup operations
- **`api`** - HTTP request/response and endpoint operations
- **`game`** - Game-specific operations and state management
- **`state`** - Data persistence and file I/O operations
- **`http`** - HTTP request details and performance metrics
- **`general`** - Default context for general operations

### Log Levels
- **`debug`** - Detailed debugging information
- **`info`** - General operational information
- **`warn`** - Warning messages for non-critical issues
- **`error`** - Error conditions with full stack traces

## 🚀 Performance Monitoring

### Timing Utilities (`logTiming`)
```typescript
// Manual timing
const startTime = logTiming.start('operation-name', 'context');
// ... do work ...
logTiming.end('operation-name', startTime, 'context', { additionalData });

// Automatic timing with async functions
const result = await logTiming.time('operation-name', async () => {
  // async operation
}, 'context');
```

### HTTP Request Monitoring
- **Request ID generation** for tracking requests across the system
- **Performance metrics** for each HTTP request
- **Header logging** for debugging and security analysis
- **Response time tracking** with millisecond precision

## 🔍 Enhanced Error Handling

### Error Logging (`logError`)
- **Structured error information** with context
- **Stack trace preservation** for debugging
- **Additional context data** for better error understanding
- **Automatic error categorization** by context

### Error Response Formatting
```typescript
// Production-safe error responses
{
  "error": "User-friendly error message",
  "details": "Stack trace (development only)"
}
```

## 📊 Logging Endpoints

### Dynamic Log Level Control
- **`POST /logs/level`** - Change log level at runtime
- **`GET /logs/stats`** - Get logging system statistics
- **Memory usage monitoring** and uptime tracking

### Health Check Enhancement
- **`GET /health`** - Enhanced with memory usage and uptime
- **Bootstrap status** tracking
- **Project initialization status**

## 🎮 Game-Specific Logging

### User Operations
- **User creation requests** with validation logging
- **Profile creation** with Honeycomb integration tracking
- **Character creation** with state persistence logging

### Game State Management
- **State file operations** with detailed I/O logging
- **Character tracking** with user association logging
- **XP operations** with reason and amount tracking

## 🏗️ Infrastructure Logging

### Server Lifecycle
- **Startup sequence** with step-by-step logging
- **Bootstrap process** with timing and status
- **Graceful shutdown** handling with cleanup logging

### Honeycomb Integration
- **Project creation** with transaction details
- **Profiles tree setup** with verification logging
- **User profile creation** with blockchain transaction tracking

## 🛠️ Development Tools

### NPM Scripts
```bash
# Different log level development modes
npm run logs:debug    # Start with debug logging
npm run logs:info     # Start with info logging
npm run logs:warn     # Start with warning-only logging
npm run logs:error    # Start with error-only logging

# Development utilities
npm run dev:watch     # Watch mode for development
npm run lint          # Type checking
npm run rebuild       # Clean build
```

### Environment Configuration
```bash
# Log level control
LOG_LEVEL=debug       # Set default log level
NODE_ENV=development  # Enable detailed error responses
```

## 📈 Monitoring and Observability

### Request Tracking
- **Unique request IDs** for correlation
- **Request/response correlation** across logs
- **Performance metrics** per request
- **Error correlation** with request context

### State Persistence Monitoring
- **File I/O operations** with timing
- **State validation** and integrity checks
- **Error recovery** with graceful fallbacks
- **Storage statistics** and health monitoring

## 🔧 Configuration and Customization

### Log Format Customization
- **Timestamp formatting** with system time
- **Color coding** for different log levels
- **Structured data** for easy parsing
- **Context filtering** for focused debugging

### Performance Tuning
- **Async operation timing** for bottleneck identification
- **Memory usage tracking** for resource monitoring
- **File I/O performance** for storage optimization
- **Network request timing** for API performance

## 🚨 Error Recovery and Resilience

### Graceful Degradation
- **Non-critical operation failures** don't crash the system
- **State corruption handling** with fallback mechanisms
- **Network failure recovery** with retry logic
- **File system error handling** with safe defaults

### Debugging Support
- **Comprehensive error context** for faster debugging
- **Request correlation** across all system components
- **Performance bottleneck identification** with timing data
- **State change tracking** for data flow analysis

## 📋 Usage Examples

### Basic Logging
```typescript
import { logContext } from './lib/logger';

// Different contexts
logContext.honeycomb('Project created', { address: projectAddress });
logContext.game('Character created', { user: userPubkey, character: charAddress });
logContext.api('User request', { method: req.method, url: req.url });
```

### Error Handling
```typescript
import { logError } from './lib/logger';

try {
  // risky operation
} catch (error) {
  logError(error, 'api', { requestId: req.requestId, user: userPubkey });
}
```

### Performance Monitoring
```typescript
import { logTiming } from './lib/logger';

const result = await logTiming.time('database-query', async () => {
  return await database.query(sql);
}, 'api');
```

This comprehensive logging system provides complete visibility into the Mancala backend operations, making debugging, monitoring, and performance optimization much easier.
