# Backend to Game Connection Guide

This guide explains how to connect the Node.js backend server to the Mancala game and test the integration.

## 🔗 **Connection Overview**

The integration works as follows:
1. **Node.js Backend** - Handles blockchain operations and data persistence
2. **Godot Game** - Sends game events and receives progression data
3. **HTTP Communication** - RESTful API calls between game and backend

## 🚀 **Quick Start**

### 1. Start the Backend Server
```bash
cd backend/
npm run dev
```

The server will start on `http://localhost:8080` and automatically bootstrap the Honeycomb project.

### 2. Configure the Game
The game is already configured to connect to `http://localhost:8080`. If you need to change the backend URL:

1. Open `Script/BackendConfig.gd`
2. Modify the `backend_url` variable
3. Set `backend_port` if different from 8080

### 3. Run the Game
1. Open the project in Godot
2. Make sure `HoneycombManager` is added to Project Settings → Autoload
3. Run the game

## 🎮 **Game Integration Points**

### Automatic Backend Connection
The `HoneycombManager` automatically:
- Connects to the backend on game start
- Performs health checks
- Initializes player profiles
- Handles connection retries

### Game Events Sent to Backend
- **Game Victory**: `on_game_won()` → XP rewards
- **Stone Captures**: `on_stones_captured()` → XP rewards  
- **Extra Turns**: `on_extra_turn()` → XP rewards
- **Fast Moves**: `on_fast_move()` → Mission progress

### Backend Responses
- **XP Grants**: Updates player progression
- **Mission Progress**: Tracks achievement completion
- **Profile Data**: Stores player information

## 🧪 **Testing the Connection**

### 1. Backend Health Check
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "ok": true,
  "timestamp": "2025-08-15T12:02:14.705Z",
  "bootstrapped": true,
  "project": "Hcqszr4c7FtVHDKb2sVB4DXPFroH7FwCLPqD2Zzr7Wrv",
  "uptime": 123.45,
  "memory": {...}
}
```

### 2. Game Project Status
```bash
curl http://localhost:8080/game/project
```

### 3. Create Test User
```bash
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"userPubkey": "test_user_12345678901234567890123456789012"}'
```

### 4. Grant XP
```bash
curl -X POST http://localhost:8080/game/grant-xp \
  -H "Content-Type: application/json" \
  -d '{"userPubkey": "test_user_12345678901234567890123456789012", "amount": 100, "reason": "Test XP grant"}'
```

## 🔧 **Configuration Options**

### BackendConfig.gd Settings
```gdscript
# Server configuration
@export var backend_url: String = "http://localhost:8080"
@export var backend_port: int = 8080
@export var use_https: bool = false
@export var timeout_seconds: float = 10.0

# Feature toggles
@export var enable_xp_tracking: bool = true
@export var enable_mission_tracking: bool = true
@export var enable_character_tracking: bool = true

# Development settings
@export var debug_mode: bool = true
@export var log_all_requests: bool = true
```

### Environment Variables
```bash
# Backend (.env file)
WALLET_PRIVATE_KEY=your_solana_wallet_private_key
HONEYCOMB_RPC=https://rpc.test.honeycombprotocol.com
HONEYCOMB_EDGE=https://edge.test.honeycombprotocol.com
LOG_LEVEL=info
```

## 📊 **Monitoring and Debugging**

### Backend Logs
The backend provides comprehensive logging:
- **Health checks**: Server status and performance
- **API requests**: All incoming requests with timing
- **Honeycomb operations**: Blockchain transaction details
- **Error handling**: Detailed error information

### Game Console
Check the Godot console for:
- Backend connection status
- HTTP request/response details
- XP and mission progress
- Error messages

### Log Levels
```bash
# Start backend with different log levels
npm run logs:debug    # Detailed debugging
npm run logs:info     # Standard information
npm run logs:warn     # Warnings only
npm run logs:error    # Errors only
```

## 🚨 **Troubleshooting**

### Common Issues

#### 1. Backend Won't Start
```bash
# Check if port is in use
lsof -i :8080

# Check environment variables
cat backend/.env

# Check dependencies
cd backend/
npm install
```

#### 2. Game Can't Connect
- Verify backend is running on `http://localhost:8080`
- Check firewall settings
- Ensure `HoneycombManager` is in Autoload
- Check Godot console for error messages

#### 3. Honeycomb Integration Issues
- Verify Solana wallet private key in `.env`
- Check Honeycomb Protocol endpoints
- Review backend logs for blockchain errors

### Debug Commands
```bash
# Backend status
curl http://localhost:8080/health

# Log statistics
curl http://localhost:8080/logs/stats

# Change log level
curl -X POST http://localhost:8080/logs/level \
  -H "Content-Type: application/json" \
  -d '{"level": "debug"}'
```

## 🔄 **Development Workflow**

### 1. Backend Development
```bash
cd backend/
npm run dev:watch  # Auto-restart on changes
```

### 2. Game Development
- Modify `Script/HoneycombManager.gd` for new features
- Update `Script/BackendConfig.gd` for configuration
- Test with `Script/BackendTest.gd`

### 3. Testing Integration
1. Start backend server
2. Run game in Godot
3. Play a game to trigger events
4. Check backend logs for API calls
5. Verify data persistence

## 📈 **Performance Monitoring**

### Backend Metrics
- Request timing and throughput
- Memory usage and uptime
- Database operation performance
- Blockchain transaction success rates

### Game Metrics
- XP progression tracking
- Mission completion rates
- Backend response times
- Connection stability

## 🔮 **Future Enhancements**

### Planned Features
- **Real-time updates**: WebSocket connections for live data
- **Offline support**: Local caching with sync on reconnection
- **Advanced missions**: Complex achievement systems
- **Social features**: Player leaderboards and competitions

### Scalability
- **Load balancing**: Multiple backend instances
- **Database optimization**: Connection pooling and indexing
- **Caching**: Redis for frequently accessed data
- **CDN**: Static asset delivery optimization

## 📚 **Additional Resources**

- [Backend README](backend/README.md) - Backend server documentation
- [Logging Features](backend/LOGGING_FEATURES.md) - Comprehensive logging guide
- [Troubleshooting](backend/TROUBLESHOOTING.md) - Common issues and solutions
- [Honeycomb Protocol Docs](https://docs.honeycombprotocol.com/) - Blockchain integration

## 🆘 **Getting Help**

If you encounter issues:

1. **Check the logs first** - Both backend and game console
2. **Verify configuration** - URLs, ports, and environment variables
3. **Test endpoints manually** - Use curl commands to isolate issues
4. **Review this guide** - Common solutions are documented here
5. **Check troubleshooting guide** - Backend-specific issues

The integration is designed to be robust and provide clear error messages to help with debugging.
