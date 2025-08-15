import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { logContext } from '../lib/logger';
import { loadState, saveState } from '../lib/state';

const gameRouter = Router();

// Input validation schemas
const grantXPSchema = z.object({
  userPubkey: z.string().min(32).max(44),
  amount: z.number().positive(),
  reason: z.string(),
  gameId: z.string().optional(),
  timestamp: z.string().optional()
});

const missionProgressSchema = z.object({
  userPubkey: z.string().min(32).max(44),
  missionId: z.string(),
  progress: z.number().nonnegative(),
  gameId: z.string().optional(),
  timestamp: z.string().optional()
});

const gameResultSchema = z.object({
  userPubkey: z.string().min(32).max(44),
  gameId: z.string(),
  result: z.enum(['win', 'loss', 'tie']),
  gameMode: z.enum(['PVP', 'PVE']),
  aiDifficulty: z.enum(['Easy', 'Medium', 'Hard']).optional(),
  stats: z.object({
    stonesCaptured: z.number().nonnegative(),
    extraTurns: z.number().nonnegative(),
    fastMoves: z.number().nonnegative(),
    playTime: z.number().nonnegative(),
    totalMoves: z.number().nonnegative()
  }),
  timestamp: z.string().optional()
});

// Helper function to get users from state
function getUsersFromState() {
  const state = loadState();
  return state.users || {};
}

// Helper function to save users to state
function saveUsersToState(users: Record<string, any>) {
  const state = loadState();
  state.users = users;
  saveState(state);
}

// Helper function to calculate level from XP
function calculateLevel(xp: number): number {
  return Math.floor(Math.sqrt(xp / 100)) + 1;
}

// Helper function to get XP required for level
function getXPForLevel(level: number): number {
  return (level - 1) * (level - 1) * 100;
}

// Get project status
gameRouter.get('/project', async (req: Request, res: Response) => {
  const requestId = `game_project_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Getting project status', { requestId });

  try {
    const state = loadState();
    const projectAddress = process.env.PROJECT_ADDRESS || state.projectAddress;
    
    res.json({
      success: true,
      project: projectAddress,
      state: state,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logContext.error('Failed to get project status', error, 'game');
    res.status(500).json({
      success: false,
      error: 'Failed to get project status'
    });
  }
});

// Grant XP to user
gameRouter.post('/grant-xp', async (req: Request, res: Response) => {
  const requestId = `grant_xp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Granting XP to user', {
    requestId,
    body: req.body
  });

  try {
    // Validate input
    const parse = grantXPSchema.safeParse(req.body);
    if (!parse.success) {
      logContext.api('Invalid XP grant data', {
        requestId,
        errors: parse.error.issues
      });
      return res.status(400).json({
        success: false,
        error: 'Invalid input data',
        details: parse.error.issues
      });
    }

    const { userPubkey, amount, reason, gameId, timestamp } = parse.data;
    
    // Get user from state
    const users = getUsersFromState();
    const user = users[userPubkey];
    
    if (!user) {
      logContext.api('User not found for XP grant', {
        requestId,
        userPubkey
      });
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Calculate old and new levels
    const oldLevel = user.stats.currentLevel;
    const oldXP = user.stats.totalXP;
    const newXP = oldXP + amount;
    const newLevel = calculateLevel(newXP);

    // Update user stats
    user.stats.totalXP = newXP;
    user.stats.currentLevel = newLevel;
    user.lastSeen = new Date().toISOString();

    // Add XP history entry
    if (!user.xpHistory) {
      user.xpHistory = [];
    }
    user.xpHistory.push({
      amount,
      reason,
      gameId,
      timestamp: timestamp || new Date().toISOString(),
      oldXP,
      newXP,
      oldLevel,
      newLevel
    });

    // Save updated user
    users[userPubkey] = user;
    saveUsersToState(users);

    logContext.api('XP granted successfully', {
      requestId,
      userPubkey,
      amount,
      reason,
      oldLevel,
      newLevel,
      oldXP,
      newXP
    });

    res.json({
      success: true,
      message: 'XP granted successfully',
      user: {
        userPubkey,
        totalXP: newXP,
        currentLevel: newLevel,
        levelUp: newLevel > oldLevel
      },
      xpGrant: {
        amount,
        reason,
        gameId,
        timestamp: timestamp || new Date().toISOString()
      }
    });

  } catch (error) {
    logContext.error('Failed to grant XP', error, 'game');
    res.status(500).json({
      success: false,
      error: 'Failed to grant XP',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Update mission progress
gameRouter.post('/mission-progress', async (req: Request, res: Response) => {
  const requestId = `mission_progress_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Updating mission progress', {
    requestId,
    body: req.body
  });

  try {
    // Validate input
    const parse = missionProgressSchema.safeParse(req.body);
    if (!parse.success) {
      logContext.api('Invalid mission progress data', {
        requestId,
        errors: parse.error.issues
      });
      return res.status(400).json({
        success: false,
        error: 'Invalid input data',
        details: parse.error.issues
      });
    }

    const { userPubkey, missionId, progress, gameId, timestamp } = parse.data;
    
    // Get user from state
    const users = getUsersFromState();
    const user = users[userPubkey];
    
    if (!user) {
      logContext.api('User not found for mission progress', {
        requestId,
        userPubkey
      });
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Update mission progress
    if (user.missions && user.missions[missionId]) {
      const mission = user.missions[missionId];
      const oldProgress = mission.current;
      mission.current = Math.min(mission.current + progress, mission.target);
      
      // Check if mission is completed
      const wasCompleted = mission.completed;
      mission.completed = mission.current >= mission.target;
      
      // If mission was just completed, grant reward XP
      let rewardXP = 0;
      if (mission.completed && !wasCompleted) {
        // Get reward XP based on mission type
        const missionRewards: Record<string, number> = {
          firstVictory: 50,
          captureMaster: 100,
          extraTurnPro: 75,
          aiSlayer: 200,
          speedDemon: 150
        };
        
        rewardXP = missionRewards[missionId] || 50;
        user.stats.missionsCompleted += 1;
        user.achievements[missionId] = true;
        
        // Grant reward XP
        const oldLevel = user.stats.currentLevel;
        const oldXP = user.stats.totalXP;
        const newXP = oldXP + rewardXP;
        const newLevel = calculateLevel(newXP);
        
        user.stats.totalXP = newXP;
        user.stats.currentLevel = newLevel;
        
        logContext.api('Mission completed and reward XP granted', {
          requestId,
          userPubkey,
          missionId,
          rewardXP,
          oldLevel,
          newLevel
        });
      }

      // Add mission progress history
      if (!user.missionHistory) {
        user.missionHistory = [];
      }
      user.missionHistory.push({
        missionId,
        progress,
        gameId,
        timestamp: timestamp || new Date().toISOString(),
        oldProgress,
        newProgress: mission.current,
        completed: mission.completed,
        rewardXP
      });

      user.lastSeen = new Date().toISOString();
      
      // Save updated user
      users[userPubkey] = user;
      saveUsersToState(users);

      logContext.api('Mission progress updated successfully', {
        requestId,
        userPubkey,
        missionId,
        progress,
        oldProgress,
        newProgress: mission.current,
        completed: mission.completed,
        rewardXP
      });

      res.json({
        success: true,
        message: 'Mission progress updated successfully',
        mission: {
          missionId,
          current: mission.current,
          target: mission.target,
          completed: mission.completed,
          wasCompleted,
          rewardXP
        },
        user: {
          userPubkey,
          totalXP: user.stats.totalXP,
          currentLevel: user.stats.currentLevel,
          missionsCompleted: user.stats.missionsCompleted
        }
      });
    } else {
      res.status(400).json({
        success: false,
        error: 'Mission not found'
      });
    }

  } catch (error) {
    logContext.error('Failed to update mission progress', error, 'game');
    res.status(500).json({
      success: false,
      error: 'Failed to update mission progress',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Record game result
gameRouter.post('/game-result', async (req: Request, res: Response) => {
  const requestId = `game_result_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Recording game result', {
    requestId,
    body: req.body
  });

  try {
    // Validate input
    const parse = gameResultSchema.safeParse(req.body);
    if (!parse.success) {
      logContext.api('Invalid game result data', {
        requestId,
        errors: parse.error.issues
      });
      return res.status(400).json({
        success: false,
        error: 'Invalid input data',
        details: parse.error.issues
      });
    }

    const { userPubkey, gameId, result, gameMode, aiDifficulty, stats, timestamp } = parse.data;
    
    // Get user from state
    const users = getUsersFromState();
    const user = users[userPubkey];
    
    if (!user) {
      logContext.api('User not found for game result', {
        requestId,
        userPubkey
      });
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Update game statistics
    user.stats.gamesPlayed += 1;
    if (result === 'win') {
      user.stats.gamesWon += 1;
    } else if (result === 'loss') {
      user.stats.gamesLost += 1;
    }
    
    user.stats.stonesCaptured += stats.stonesCaptured;
    user.stats.extraTurns += stats.extraTurns;
    user.stats.fastMoves += stats.fastMoves;
    user.stats.totalPlayTime += stats.playTime;
    
    // Update game mode preferences
    user.gameMode = gameMode;
    if (aiDifficulty) {
      user.aiDifficulty = aiDifficulty;
    }

    // Add game history
    if (!user.gameHistory) {
      user.gameHistory = [];
    }
    user.gameHistory.push({
      gameId,
      result,
      gameMode,
      aiDifficulty,
      stats,
      timestamp: timestamp || new Date().toISOString()
    });

    user.lastSeen = new Date().toISOString();
    
    // Save updated user
    users[userPubkey] = user;
    saveUsersToState(users);

    logContext.api('Game result recorded successfully', {
      requestId,
      userPubkey,
      gameId,
      result,
      gameMode,
      aiDifficulty,
      stats
    });

    res.json({
      success: true,
      message: 'Game result recorded successfully',
      gameResult: {
        gameId,
        result,
        gameMode,
        aiDifficulty,
        stats
      },
      user: {
        userPubkey,
        gamesPlayed: user.stats.gamesPlayed,
        gamesWon: user.stats.gamesWon,
        gamesLost: user.stats.gamesLost,
        totalXP: user.stats.totalXP,
        currentLevel: user.stats.currentLevel
      }
    });

  } catch (error) {
    logContext.error('Failed to record game result', error, 'game');
    res.status(500).json({
      success: false,
      error: 'Failed to record game result',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Get user statistics
gameRouter.get('/stats/:userPubkey', async (req: Request, res: Response) => {
  const userPubkey = req.params.userPubkey as string;
  const requestId = `get_stats_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Getting user statistics', {
    requestId,
    userPubkey
  });

  try {
    const users = getUsersFromState();
    const user = users[userPubkey];
    
    if (!user) {
      logContext.api('User not found for stats', {
        requestId,
        userPubkey
      });
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Calculate additional stats
    const winRate = user.stats.gamesPlayed > 0 ? (user.stats.gamesWon / user.stats.gamesPlayed * 100).toFixed(1) : "0";
    const nextLevelXP = getXPForLevel(user.stats.currentLevel + 1);
    const xpToNextLevel = nextLevelXP - user.stats.totalXP;

    res.json({
      success: true,
      user: {
        userPubkey,
        username: user.username,
        displayName: user.displayName,
        stats: {
          ...user.stats,
          winRate: parseFloat(winRate),
          nextLevelXP,
          xpToNextLevel
        },
        achievements: user.achievements,
        missions: user.missions,
        gameMode: user.gameMode,
        aiDifficulty: user.aiDifficulty,
        lastSeen: user.lastSeen
      }
    });

  } catch (error) {
    logContext.error('Failed to get user statistics', error, 'game');
    res.status(500).json({
      success: false,
      error: 'Failed to get user statistics',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export default gameRouter;
