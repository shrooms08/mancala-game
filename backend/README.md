# Mancala Game Backend

A Node.js backend server for the Mancala blockchain game, integrated with Honeycomb Protocol for on-chain game progression, user profiles, and achievements.

## Features

- **Honeycomb Protocol Integration**: Automatic project creation and profiles tree setup
- **User Management**: Create users and profiles on-chain
- **Game State**: Track characters, XP, and game statistics
- **Comprehensive Logging**: Structured logging with different contexts and levels
- **RESTful API**: Clean endpoints for game operations

## Logging System

The backend uses a centralized logging system with structured logging for clear visibility:

### Log Contexts

- **`honeycomb`**: Blockchain operations and Honeycomb Protocol interactions
- **`server`**: Server lifecycle and bootstrap operations
- **`api`**: HTTP request/response logging
- **`game`**: Game-specific operations and state management
- **`state`**: Data persistence operations
- **`http`**: HTTP request details and performance metrics

### Log Levels

- **`info`**: General operational information
- **`warn`**: Warning messages for non-critical issues
- **`error`**: Error conditions with full stack traces
- **`debug`**: Detailed debugging information

### Environment Variables

```bash
# Required
WALLET_PRIVATE_KEY=your_solana_wallet_private_key

# Optional
LOG_LEVEL=info                    # Log level (debug, info, warn, error)
HONEYCOMB_RPC=https://rpc.test.honeycombprotocol.com
HONEYCOMB_EDGE=https://edge.test.honeycombprotocol.com
PROJECT_NAME=Mancala Blockchain Game
PROJECT_DESCRIPTION=A strategic Mancala game with on-chain progression
```

## API Endpoints

### Health & Status
- `GET /health` - Server health check
- `POST /init` - Manual project initialization

### Users
- `POST /users` - Create user and profile
- `GET /users/:userPubkey` - Get user profile (placeholder)

### Game Operations
- `GET /game/project` - Get project state and configuration
- `POST /game/character` - Create game character
- `POST /game/grant-xp` - Grant XP to player
- `GET /game/stats/:userPubkey` - Get player statistics

## Development

### Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Copy environment template:
   ```bash
   cp .env.example .env
   ```

3. Fill in your Solana wallet private key in `.env`

4. Start development server:
   ```bash
   npm run dev
   ```

### Build

```bash
npm run build
npm start
```

### Logging Examples

```typescript
import { logContext } from './lib/logger';

// Different log contexts
logContext.honeycomb('Project created successfully', { projectAddress });
logContext.game('Character created', { userPubkey, characterAddress });
logContext.api('User registration request', { body: req.body });

// Error logging with context
logContext.error('Failed to create project', error, 'honeycomb');

// Warning logging
logContext.warn('Feature not yet implemented', { feature: 'missions' }, 'game');
```

## Project Structure

```
src/
├── lib/
│   ├── logger.ts          # Centralized logging system
│   ├── honeycomb.ts       # Honeycomb Protocol integration
│   └── state.ts           # State persistence utilities
├── routes/
│   ├── users.ts           # User management endpoints
│   └── game.ts            # Game operation endpoints
└── server.ts              # Main server entry point
```

## Honeycomb Integration

The backend automatically:

1. **Creates a Project**: On first startup, creates a Honeycomb project for the Mancala game
2. **Sets up Profiles Tree**: Ensures the profiles tree exists for user management
3. **Manages Users**: Creates user profiles on-chain when requested
4. **Tracks Game State**: Maintains character and progression data

## Error Handling

- Comprehensive error logging with stack traces
- Graceful fallbacks for non-critical operations
- Structured error responses with context
- Automatic error reporting to logs

## Performance Monitoring

- Request timing and performance metrics
- Automatic HTTP request/response logging
- State operation performance tracking
- Memory and file I/O monitoring

## Security

- Input validation with Zod schemas
- Environment variable validation
- Secure error handling (no sensitive data in production)
- CORS configuration for frontend integration
