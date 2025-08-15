# Mancala Game - Blockchain Integration Guide

## Overview

The Mancala game has been successfully integrated with a Node.js backend and blockchain wallet system. This integration provides:

- **Automatic wallet creation** when users click "Play Game"
- **Backend user management** with blockchain profiles
- **Mission tracking** and XP rewards
- **Blockchain integration** for storing game progress
- **Real-time game statistics** and achievements

## Architecture

### Frontend (Godot)
- **Wallet Connect UI**: Handles wallet creation and connection
- **GameProgressTracker**: Manages game events and backend communication
- **BlockchainManager**: Handles blockchain interactions and Honeycomb Protocol
- **Main Game**: Enhanced with mission tracking and reward distribution

### Backend (Node.js)
- **User Management**: Creates and manages user profiles
- **Game Tracking**: Records game results and statistics
- **Mission System**: Tracks mission progress and completion
- **XP Rewards**: Manages experience points and leveling

## Integration Flow

### 1. User Journey

```
1. User opens game
2. Clicks "Play Game" button
3. System checks for wallet connection
4. If no wallet: Redirects to wallet creation
5. Creates new blockchain wallet
6. Initializes user profile in backend
7. Sets up blockchain character and missions
8. Proceeds to game selection
```

### 2. Game Session

```
1. User selects game mode (PVP/PVE)
2. Game starts with backend tracking
3. Game events are recorded:
   - Stone captures
   - Extra turns
   - Fast moves
   - Game victories
4. Mission progress is updated
5. XP rewards are distributed
6. Game results are saved to backend
```

### 3. Blockchain Integration

```
1. Honeycomb Protocol project initialization
2. Character NFT creation
3. Mission contracts setup
4. Real-time progress tracking
5. Reward distribution on-chain
6. Achievement verification
```

## Key Components

### Wallet System

The wallet system provides two options:
- **Create New Wallet**: Generates a new blockchain wallet for the user
- **Connect Existing Wallet**: Connects to an existing wallet (Phantom, Solflare, etc.)

```gdscript
# Example wallet creation
var blockchain_manager = get_node("/root/BlockchainManager")
var wallet_data = blockchain_manager.create_new_wallet()
```

### Mission System

Five core missions are tracked:
1. **First Victory**: Win your first game (50 XP)
2. **Capture Master**: Capture 10 stones total (100 XP)
3. **Extra Turn Pro**: Get 5 extra turns in games (75 XP)
4. **AI Slayer**: Beat Hard AI 3 times (200 XP)
5. **Speed Demon**: Make 10 moves in under 5 seconds (150 XP)

### Backend API Endpoints

- `POST /users` - Create new user
- `GET /users/:userPubkey` - Get user profile
- `POST /game/grant-xp` - Grant XP rewards
- `POST /game/mission-progress` - Update mission progress
- `POST /game/game-result` - Record game results
- `GET /game/stats/:userPubkey` - Get user statistics

## Setup Instructions

### 1. Backend Setup

```bash
cd backend
npm install
npm run dev
```

The backend will start on `http://localhost:8080`

### 2. Godot Configuration

Add the following autoloads in Project Settings:
- `GameProgressTracker` (Script/GameProgressTracker.gd)
- `HoneycombManager` (Script/HoneycombManager.gd)
- `BlockchainManager` (Script/BlockchainManager.gd)
- `GameGlobals` (Script/GameGlobals.gd)

### 3. Environment Variables

Create a `.env` file in the backend directory:

```env
HONEYCOMB_EDGE=https://edge.honeycomb.xyz
HONEYCOMB_RPC=https://api.mainnet-beta.solana.com
PORT=8080
NODE_ENV=development
```

## Usage Examples

### Creating a New User

```gdscript
# In Wallet Connect UI
func on_create_wallet_pressed():
    var wallet_data = progress_tracker.create_blockchain_wallet()
    var success = progress_tracker.create_or_get_user(
        wallet_data.address, 
        "Player_" + wallet_data.address.slice(0, 8)
    )
```

### Recording Game Events

```gdscript
# In main game
func record_stone_capture(captured_stones: int):
    if progress_tracker:
        progress_tracker.record_stone_capture(captured_stones)
```

### Granting XP Rewards

```gdscript
# Grant XP for game victory
func on_game_victory(vs_ai: bool, ai_difficulty: String = ""):
    if progress_tracker:
        progress_tracker.record_game_victory(vs_ai, ai_difficulty)
```

## Blockchain Features

### Honeycomb Protocol Integration

The game integrates with Honeycomb Protocol for:
- **Character NFTs**: Each user gets a unique character NFT
- **Mission Contracts**: On-chain mission tracking and verification
- **Reward Distribution**: Automated token and NFT rewards
- **Achievement System**: Verifiable achievements on blockchain

### Wallet Security

- Private keys are generated using proper cryptographic methods
- Wallet data is stored securely
- All transactions are signed and verified
- Support for hardware wallets and wallet providers

## Testing

### Backend Health Check

```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "ok": true,
  "bootstrapped": true,
  "project": "honeycomb_project_...",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Create Test User

```bash
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{
    "userPubkey": "test_wallet_123",
    "username": "TestPlayer",
    "displayName": "Test Player"
  }'
```

### Grant XP

```bash
curl -X POST http://localhost:8080/game/grant-xp \
  -H "Content-Type: application/json" \
  -d '{
    "userPubkey": "test_wallet_123",
    "amount": 100,
    "reason": "Game Victory"
  }'
```

## Monitoring and Logging

### Backend Logs

The backend includes comprehensive logging:
- Request/response logging
- Error tracking
- Performance metrics
- Blockchain transaction logs

### Game Events

All game events are logged:
- Wallet creation/connection
- User profile creation
- Game start/end
- Mission progress
- XP rewards

## Troubleshooting

### Common Issues

1. **Backend Connection Failed**
   - Check if backend is running on port 8080
   - Verify firewall settings
   - Check network connectivity

2. **Wallet Creation Failed**
   - Ensure blockchain configuration is correct
   - Check Honeycomb Protocol connectivity
   - Verify environment variables

3. **Mission Progress Not Updating**
   - Check backend connection
   - Verify user authentication
   - Check mission configuration

### Debug Mode

Enable debug logging:

```bash
# Backend
LOG_LEVEL=debug npm run dev

# Godot
# Check console output for detailed logs
```

## Future Enhancements

### Planned Features

1. **Multi-chain Support**: Support for multiple blockchain networks
2. **Advanced Missions**: More complex mission types
3. **Tournament System**: Competitive play with blockchain rewards
4. **NFT Marketplace**: Trade game items and characters
5. **Social Features**: Friend system and leaderboards

### Technical Improvements

1. **Real-time Updates**: WebSocket integration for live updates
2. **Offline Support**: Local caching with sync when online
3. **Performance Optimization**: Caching and optimization
4. **Security Enhancements**: Advanced wallet security features

## Support

For technical support or questions about the integration:

1. Check the backend logs for error messages
2. Review the Godot console output
3. Verify all configuration settings
4. Test with the provided API endpoints

## License

This integration is provided as-is for educational and development purposes. Ensure compliance with all applicable blockchain and gaming regulations in your jurisdiction.
