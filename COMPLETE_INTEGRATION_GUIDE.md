# 🎮 Complete Backend Integration Guide for Mancala Game

This guide explains how the entire Mancala game is now connected to the Node.js backend for comprehensive user progress tracking and blockchain integration via Honeycomb Protocol.

## 🏗️ **System Architecture Overview**

```
┌─────────────────┐    HTTP API    ┌──────────────────┐    Blockchain    ┌─────────────────┐
│   Godot Game    │ ◄────────────► │  Node.js Backend │ ◄──────────────► │ Honeycomb Proto │
│                 │                │                  │                  │                 │
│ • Game Logic    │                │ • User Mgmt      │                  │ • User Profiles │
│ • Progress      │                │ • XP Tracking    │                  │ • XP Resources  │
│ • Missions      │                │ • Mission Mgmt   │                  │ • Achievements  │
│ • Achievements  │                │ • Game Stats     │                  │ • Game Data     │
└─────────────────┘                └──────────────────┘                  └─────────────────┘
```

## 🔄 **Complete Game Flow Integration**

### 1. **Game Startup**
- **Wallet Connection**: User connects wallet (simulated for demo)
- **User Creation**: Backend creates/retrieves user profile
- **Game Initialization**: Progress tracker starts monitoring

### 2. **During Gameplay**
- **Move Tracking**: Every move is recorded with timing
- **Event Recording**: Captures, extra turns, fast moves tracked
- **Real-time Updates**: Progress sent to backend immediately

### 3. **Game Completion**
- **Final Stats**: Complete game statistics compiled
- **XP Rewards**: Victory bonuses and mission rewards granted
- **Mission Progress**: All achievements updated
- **Data Persistence**: Everything saved to backend and blockchain

## 📊 **What Gets Tracked**

### **Game Statistics**
- **Games Played/Won/Lost**: Win rate calculation
- **Total Play Time**: Session duration tracking
- **Move Count**: Total moves per game
- **AI Difficulty**: Performance vs different AI levels

### **Player Progression**
- **Experience Points (XP)**: Level-based progression system
- **Current Level**: Calculated from total XP
- **Achievements**: Unlocked mission completions
- **Game Preferences**: PVP/PVE and AI difficulty choices

### **Mission System**
- **First Victory**: Win your first game (+50 XP)
- **Capture Master**: Capture 10 stones total (+100 XP)
- **Extra Turn Pro**: Get 5 extra turns (+75 XP)
- **AI Slayer**: Beat Hard AI 3 times (+200 XP)
- **Speed Demon**: Make 10 moves under 5 seconds (+150 XP)

### **Performance Metrics**
- **Stone Captures**: Strategic play tracking
- **Extra Turns**: Skill-based rewards
- **Fast Moves**: Quick thinking bonuses
- **Game Mode Performance**: PVP vs PVE statistics

## 🚀 **How to Use the Integrated System**

### **1. Start the Backend**
```bash
cd backend/
npm run dev
```

### **2. Configure the Game**
- Add `GameProgressTracker` to **Project Settings → Autoload**
- Ensure backend URL is correct in `Script/BackendConfig.gd`

### **3. Run the Game**
1. **Wallet Connection**: Simulated wallet connection
2. **User Creation**: Automatic backend user profile creation
3. **Game Selection**: Choose PVP or PVE mode
4. **Play Game**: All progress automatically tracked
5. **View Results**: Check backend for complete statistics

## 🔧 **Backend API Endpoints**

### **User Management**
```bash
# Create/Get User
POST /users
{
  "userPubkey": "wallet_address",
  "username": "Player_123",
  "displayName": "Player Name"
}

# Get User Profile
GET /users/:userPubkey

# Update User
PUT /users/:userPubkey
{
  "gameMode": "PVE",
  "aiDifficulty": "Hard"
}
```

### **Game Progress**
```bash
# Grant XP
POST /game/grant-xp
{
  "userPubkey": "wallet_address",
  "amount": 100,
  "reason": "Game Victory",
  "gameId": "game_123"
}

# Mission Progress
POST /game/mission-progress
{
  "userPubkey": "wallet_address",
  "missionId": "firstVictory",
  "progress": 1,
  "gameId": "game_123"
}

# Game Result
POST /game/game-result
{
  "userPubkey": "wallet_address",
  "gameId": "game_123",
  "result": "win",
  "gameMode": "PVE",
  "aiDifficulty": "Hard",
  "stats": {
    "stonesCaptured": 5,
    "extraTurns": 2,
    "fastMoves": 3,
    "playTime": 180,
    "totalMoves": 25
  }
}
```

### **Statistics & Analytics**
```bash
# Get User Stats
GET /game/stats/:userPubkey

# Get All Users
GET /users

# Project Status
GET /game/project
```

## 🎯 **Game Event Integration Points**

### **Main Game Script (`main.gd`)**
```gdscript
# Game start
progress_tracker.start_new_game(game_mode, ai_difficulty)

# Move recording
progress_tracker.record_move()

# Stone capture
progress_tracker.record_stone_capture(captured_stones)

# Extra turn
progress_tracker.record_extra_turn()

# Fast move
progress_tracker.record_fast_move(move_time)

# Game victory
progress_tracker.record_game_victory(vs_ai, ai_difficulty)

# Game end
progress_tracker.end_game(result, final_stats)
```

### **Wallet Connection (`Wallet connect UI.gd`)**
```gdscript
# User creation
progress_tracker.create_or_get_user(wallet_address, username, display_name)
```

## 📈 **Data Flow Examples**

### **Example 1: Player Wins vs Hard AI**
```
1. Game Start → progress_tracker.start_new_game("PVE", "Hard")
2. Move Made → progress_tracker.record_move()
3. Stones Captured → progress_tracker.record_stone_capture(3)
4. Extra Turn → progress_tracker.record_extra_turn()
5. Victory → progress_tracker.record_game_victory(true, "Hard")
6. Game End → progress_tracker.end_game("win", stats)
7. Backend → XP granted, missions updated, blockchain updated
```

### **Example 2: Mission Completion**
```
1. Player captures 10th stone → captureMaster mission progress +1
2. Mission target reached → Backend grants +100 XP reward
3. Level calculation → New level determined
4. Achievement unlocked → captureMaster marked as completed
5. Blockchain update → Honeycomb Protocol updated
```

## 🔍 **Monitoring and Debugging**

### **Backend Logs**
```bash
# View all logs
npm run logs:debug

# Check specific endpoints
curl http://localhost:8080/health
curl http://localhost:8080/users
curl http://localhost:8080/game/project
```

### **Game Console**
- Backend connection status
- API request/response details
- Progress tracking events
- Error messages and debugging info

### **Data Verification**
```bash
# Check user creation
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"userPubkey": "test_user_123", "username": "TestPlayer"}'

# Verify user exists
curl http://localhost:8080/users/test_user_123

# Check game stats
curl http://localhost:8080/game/stats/test_user_123
```

## 🚨 **Troubleshooting Common Issues**

### **Backend Connection Issues**
1. **Check if backend is running**: `curl http://localhost:8080/health`
2. **Verify port availability**: `lsof -i :8080`
3. **Check firewall settings**: Ensure port 8080 is accessible
4. **Review backend logs**: Look for startup errors

### **Game Integration Issues**
1. **Autoload not set**: Ensure `GameProgressTracker` is in Project Settings
2. **Backend URL incorrect**: Check `Script/BackendConfig.gd`
3. **User not created**: Verify wallet connection flow
4. **Progress not tracked**: Check console for error messages

### **Data Persistence Issues**
1. **State file permissions**: Check `backend/data/` directory
2. **Database errors**: Review backend error logs
3. **Honeycomb integration**: Verify blockchain connection
4. **API validation**: Check request/response format

## 🔮 **Future Enhancements**

### **Planned Features**
- **Real-time multiplayer**: WebSocket connections for live games
- **Leaderboards**: Global player rankings
- **Tournaments**: Scheduled competitive events
- **Social features**: Friend lists and challenges
- **Advanced analytics**: Detailed performance insights

### **Blockchain Integration**
- **NFT achievements**: Mintable achievement tokens
- **XP trading**: Transferable experience points
- **Governance**: Player voting on game updates
- **Cross-game progression**: Shared achievements across games

## 📚 **File Structure Reference**

```
mancala-game/
├── Script/
│   ├── GameProgressTracker.gd     # Main integration script
│   ├── main.gd                    # Updated game logic
│   ├── Wallet connect UI.gd       # User creation
│   ├── BackendConfig.gd           # Configuration
│   └── GameGlobals.gd             # Game state management
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   │   ├── users.ts           # User management API
│   │   │   └── game.ts            # Game progress API
│   │   ├── lib/
│   │   │   ├── honeycomb.ts       # Blockchain integration
│   │   │   ├── state.ts           # Data persistence
│   │   │   └── logger.ts          # Comprehensive logging
│   │   └── server.ts              # Main server
│   └── package.json               # Dependencies
└── scene/
    ├── main.tscn                  # Main game scene
    ├── main_menu.tscn             # Menu scene
    └── wallet_ui.tscn             # Wallet connection
```

## 🎉 **Success Indicators**

### **When Everything Works:**
1. ✅ Backend starts without errors
2. ✅ Game connects to backend on startup
3. ✅ User profile created automatically
4. ✅ All game events tracked in real-time
5. ✅ XP and missions progress correctly
6. ✅ Data persists between game sessions
7. ✅ Backend logs show successful API calls
8. ✅ Blockchain integration (when available)

### **Testing Checklist:**
- [ ] Backend health check passes
- [ ] User creation works
- [ ] Game progress tracking functions
- [ ] XP rewards granted correctly
- [ ] Mission progress updates
- [ ] Game results submitted
- [ ] Statistics retrieved properly
- [ ] Data persists after restart

## 🆘 **Getting Help**

### **Immediate Issues:**
1. Check backend logs: `npm run logs:debug`
2. Verify game console output
3. Test API endpoints manually
4. Review this integration guide

### **Advanced Debugging:**
1. Enable detailed logging: `npm run logs:debug`
2. Check network requests in browser dev tools
3. Verify database state files
4. Review blockchain transaction logs

The integration is designed to be robust and provide clear feedback at every step. If you encounter issues, the comprehensive logging system will help identify and resolve problems quickly.
