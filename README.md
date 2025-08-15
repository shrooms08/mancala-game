# 🎮 Mancala Game

A modern, blockchain-integrated Mancala game built with **Godot 4.4** and **Node.js**, featuring on-chain progression tracking via the **Honeycomb Protocol**.

![Mancala Game](https://img.shields.io/badge/Godot-4.4-478CBF?style=for-the-badge&logo=godot-engine)
![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=node.js)
![Solana](https://img.shields.io/badge/Solana-14CDFF?style=for-the-badge&logo=solana)
![Honeycomb](https://img.shields.io/badge/Honeycomb-Protocol-FF6B35?style=for-the-badge)

## 🌟 Features

### 🎯 **Core Gameplay**
- **Classic Mancala Rules**: Traditional 6-pit, 4-stone gameplay
- **Multiple Game Modes**: Player vs Player (PVP) and Player vs AI (PVE)
- **AI Difficulty Levels**: Easy, Medium, and Hard AI opponents
- **Real-time Game Logic**: Smooth turn-based gameplay with visual feedback

### 🏆 **Progression System**
- **Experience Points (XP)**: Earn XP through gameplay achievements
- **Level Progression**: Level up based on total XP earned
- **Mission System**: Complete challenges for bonus rewards
- **Achievement Tracking**: Unlock achievements for various accomplishments

### ⛓️ **Blockchain Integration**
- **Honeycomb Protocol**: On-chain user profiles and progression
- **Solana Wallet Integration**: Secure wallet connection and management
- **Persistent Game Data**: All progress saved on-chain
- **Decentralized Identity**: User profiles stored on blockchain

### 🎨 **Modern UI/UX**
- **Responsive Design**: Optimized for both desktop and mobile
- **Beautiful Graphics**: Custom sprites and modern visual design
- **Smooth Animations**: Fluid stone movement and game transitions
- **Intuitive Controls**: Easy-to-use interface for all skill levels

## 🏗️ Architecture

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

## 🚀 Quick Start

### Prerequisites
- **Godot 4.4+** ([Download](https://godotengine.org/download))
- **Node.js 18+** ([Download](https://nodejs.org/))
- **Solana Wallet** (Phantom, Solflare, etc.)

### 1. Clone the Repository
```bash
git clone <repository-url>
cd mancala-game
```

### 2. Start the Backend Server
```bash
cd backend/
npm install
npm run dev
```

### 3. Configure Environment Variables
Create a `.env` file in the `backend/` directory:
```bash
WALLET_PRIVATE_KEY=your_solana_wallet_private_key
LOG_LEVEL=info
HONEYCOMB_RPC=https://rpc.test.honeycombprotocol.com
HONEYCOMB_EDGE=https://edge.test.honeycombprotocol.com
PROJECT_NAME=Mancala Blockchain Game
PROJECT_DESCRIPTION=A strategic Mancala game with on-chain progression
```

### 4. Open in Godot
1. Open **Godot 4.4**
2. Click **Import** and select the project folder
3. Click **Import & Edit**
4. Press **F5** or click **Play** to run the game

## 🎮 How to Play

### Basic Rules
1. **Setup**: Each player has 6 pits with 4 stones each, plus a store
2. **Objective**: Capture more stones than your opponent
3. **Turns**: Pick up all stones from one of your pits
4. **Distribution**: Drop one stone in each pit as you move counterclockwise
5. **Capturing**: If your last stone lands in an empty pit on your side, capture stones from the opposite pit
6. **Extra Turns**: If your last stone lands in your store, you get another turn
7. **Game End**: When one player has no stones left in their pits

### Game Modes
- **PVP Mode**: Play against another human player
- **PVE Mode**: Challenge AI with three difficulty levels
  - **Easy**: Basic AI for beginners
  - **Medium**: Balanced AI for casual players
  - **Hard**: Advanced AI for experienced players

### Mission System
Complete missions to earn XP and level up:

- **First Victory** (+50 XP): Win your first game
- **Capture Master** (+100 XP): Capture 10 stones total
- **Extra Turn Pro** (+75 XP): Get 5 extra turns in games
- **AI Slayer** (+200 XP): Beat Hard AI 3 times
- **Speed Demon** (+150 XP): Make 10 moves in under 5 seconds

## 🔧 Development Setup

### Project Structure
```
mancala-game/
├── backend/                 # Node.js backend server
│   ├── src/
│   │   ├── lib/            # Core libraries
│   │   ├── routes/         # API endpoints
│   │   └── server.ts       # Main server
│   ├── package.json        # Backend dependencies
│   └── README.md           # Backend documentation
├── Script/                 # Godot scripts
│   ├── GameGlobals.gd      # Global game state
│   ├── HoneycombManager.gd # Blockchain integration
│   ├── play_game.gd        # Main game logic
│   └── ...                 # Other game scripts
├── scene/                  # Godot scene files
├── Mancala/                # Game assets
├── project.godot           # Godot project configuration
└── README.md               # This file
```

### Backend API Endpoints

#### Health & Status
- `GET /health` - Server health check
- `POST /init` - Manual project initialization

#### User Management
- `POST /users` - Create user and profile
- `GET /users/:userPubkey` - Get user profile

#### Game Operations
- `GET /game/project` - Get project state
- `POST /game/character` - Create game character
- `POST /game/grant-xp` - Grant XP to player
- `GET /game/stats/:userPubkey` - Get player statistics

### Autoload Configuration
Ensure these scripts are added to **Project Settings → Autoload**:
- `GameGlobals` → `Script/GameGlobals.gd`
- `HoneycombManager` → `Script/HoneycombManager.gd`
- `GameProgressTracker` → `Script/GameProgressTracker.gd`

## 🎯 Game Features

### Progression Tracking
- **Real-time Statistics**: Games played, won, lost, win rate
- **Performance Metrics**: Move count, play time, AI difficulty performance
- **Achievement System**: Mission completion tracking
- **Level System**: XP-based progression with rewards

### Blockchain Features
- **User Profiles**: On-chain identity management
- **Persistent Data**: All progress saved to blockchain
- **Decentralized Storage**: No central server dependency
- **Secure Transactions**: Solana blockchain security

### AI System
- **Multiple Difficulties**: Easy, Medium, Hard
- **Strategic Play**: AI makes intelligent moves
- **Adaptive Behavior**: Different strategies per difficulty
- **Performance Tracking**: AI vs human statistics

## 🛠️ Troubleshooting

### Common Issues

#### Backend Connection Failed
```bash
# Check if backend is running
curl http://localhost:3000/health

# Restart backend
cd backend/
npm run dev
```

#### Godot Autoload Errors
1. Check **Project Settings → Autoload**
2. Ensure all required scripts are added
3. Verify script paths are correct
4. Restart Godot if needed

#### Wallet Connection Issues
1. Ensure Solana wallet is installed
2. Check network connection (Devnet/Mainnet)
3. Verify wallet has sufficient SOL for transactions
4. Check browser console for errors

### Debug Mode
Enable debug logging in backend:
```bash
cd backend/
LOG_LEVEL=debug npm run dev
```

## 📊 Performance

### Game Performance
- **60 FPS**: Smooth gameplay on modern devices
- **Mobile Optimized**: Responsive design for touch devices
- **Memory Efficient**: Optimized asset loading and management
- **Fast Loading**: Quick game startup and scene transitions

### Backend Performance
- **RESTful API**: Fast HTTP responses
- **Structured Logging**: Comprehensive debugging information
- **Error Handling**: Graceful failure recovery
- **Scalable Architecture**: Ready for production deployment

## 🤝 Contributing

### Development Guidelines
1. **Code Style**: Follow Godot GDScript conventions
2. **Testing**: Test on multiple devices and platforms
3. **Documentation**: Update docs for new features
4. **Performance**: Monitor and optimize performance

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Godot Engine**: For the amazing game development platform
- **Honeycomb Protocol**: For blockchain integration capabilities
- **Solana**: For fast and secure blockchain infrastructure
- **Mancala Community**: For preserving this ancient game

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)
- **Documentation**: [Wiki](https://github.com/your-repo/wiki)

---

**Happy Gaming! 🎮✨**

*Built with ❤️ using Godot 4.4 and the Honeycomb Protocol*
