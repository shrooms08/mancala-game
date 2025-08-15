import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { logContext } from '../lib/logger';
import { loadState, saveState } from '../lib/state';

const usersRouter = Router();

// Input validation schemas
const createUserSchema = z.object({
  userPubkey: z.string().min(16).max(64), // User ID or wallet address
  username: z.string().optional(),
  displayName: z.string().optional(),
  avatar: z.string().optional(),
  gameMode: z.enum(['PVP', 'PVE']).optional(),
  aiDifficulty: z.enum(['Easy', 'Medium', 'Hard']).optional()
});

const updateUserSchema = z.object({
  username: z.string().optional(),
  displayName: z.string().optional(),
  avatar: z.string().optional(),
  gameMode: z.enum(['PVP', 'PVE']).optional(),
  aiDifficulty: z.enum(['Easy', 'Medium', 'Hard']).optional()
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

// Helper function to get users list from state
function getUsersListFromState() {
  const state = loadState();
  return state.usersList || [];
}

// Helper function to save users list to state
function saveUsersListToState(usersList: string[]) {
  const state = loadState();
  state.usersList = usersList;
  saveState(state);
}

// Create new user and profile
usersRouter.post('/', async (req: Request, res: Response) => {
  const startTime = Date.now();
  const requestId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Creating new user', {
    requestId,
    body: req.body,
    headers: req.headers
  });

  try {
    // Validate input
    const parse = createUserSchema.safeParse(req.body);
    if (!parse.success) {
      logContext.api('Invalid input data', {
        requestId,
        errors: parse.error.issues
      });
      return res.status(400).json({
        success: false,
        error: 'Invalid input data',
        details: parse.error.issues
      });
    }

    const { userPubkey, username, displayName, avatar, gameMode, aiDifficulty } = parse.data;
    
    // Check if user already exists
    const users = getUsersFromState();
    const existingUser = users[userPubkey];
    if (existingUser) {
      logContext.api('User already exists', {
        requestId,
        userPubkey,
        existingUserId: existingUser.id
      });
      return res.status(200).json({
        success: true,
        message: 'User already exists',
        user: existingUser,
        isNew: false
      });
    }

    // Create local user record (Honeycomb integration will be added later)
    const newUser = {
      id: userPubkey,
      userPubkey,
      username: username || `Player_${userPubkey.slice(0, 8)}`,
      displayName: displayName || username || `Player_${userPubkey.slice(0, 8)}`,
      avatar: avatar || '',
      gameMode: gameMode || 'PVP',
      aiDifficulty: aiDifficulty || 'Medium',
      honeycombProfile: null, // Will be set when Honeycomb integration is complete
      createdAt: new Date().toISOString(),
      lastSeen: new Date().toISOString(),
      stats: {
        gamesPlayed: 0,
        gamesWon: 0,
        gamesLost: 0,
        totalXP: 0,
        currentLevel: 1,
        stonesCaptured: 0,
        extraTurns: 0,
        fastMoves: 0,
        missionsCompleted: 0,
        totalPlayTime: 0
      },
      achievements: {
        firstVictory: false,
        captureMaster: false,
        extraTurnPro: false,
        aiSlayer: false,
        speedDemon: false
      },
      missions: {
        firstVictory: { current: 0, target: 1, completed: false },
        captureMaster: { current: 0, target: 10, completed: false },
        extraTurnPro: { current: 0, target: 5, completed: false },
        aiSlayer: { current: 0, target: 3, completed: false },
        speedDemon: { current: 0, target: 10, completed: false }
      }
    };

    // Save user to state
    users[userPubkey] = newUser;
    saveUsersToState(users);
    
    // Update users list
    const usersList = getUsersListFromState();
    usersList.push(userPubkey);
    saveUsersListToState(usersList);

    const responseTime = Date.now() - startTime;
    logContext.api('User created successfully', {
      requestId,
      userPubkey,
      responseTime,
      honeycombProfile: 'skipped'
    });

    res.status(201).json({
      success: true,
      message: 'User created successfully',
      user: newUser,
      isNew: true,
      honeycombProfile: 'skipped'
    });

  } catch (error) {
    const responseTime = Date.now() - startTime;
    logContext.error('Failed to create user', error, 'users');

    res.status(500).json({
      success: false,
      error: 'Failed to create user',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Get user profile
usersRouter.get('/:userPubkey', async (req: Request, res: Response) => {
  const { userPubkey } = req.params;
  const requestId = `user_get_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Getting user profile', {
    requestId,
    userPubkey
  });

  try {
    const users = getUsersFromState();
    const user = users[userPubkey];
    if (!user) {
      logContext.api('User not found', {
        requestId,
        userPubkey
      });
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Update last seen
    user.lastSeen = new Date().toISOString();
    users[userPubkey] = user;
    saveUsersToState(users);

    logContext.api('User profile retrieved successfully', {
      requestId,
      userPubkey
    });

    res.json({
      success: true,
      user
    });

  } catch (error) {
    logContext.error('Failed to get user profile', error, 'users');

    res.status(500).json({
      success: false,
      error: 'Failed to get user profile',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Update user profile
usersRouter.put('/:userPubkey', async (req: Request, res: Response) => {
  const { userPubkey } = req.params;
  const requestId = `user_update_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Updating user profile', {
    requestId,
    userPubkey,
    body: req.body
  });

  try {
    // Validate input
    const parse = updateUserSchema.safeParse(req.body);
    if (!parse.success) {
      logContext.api('Invalid input data for update', {
        requestId,
        errors: parse.error.issues
      });
      return res.status(400).json({
        success: false,
        error: 'Invalid input data',
        details: parse.error.issues
      });
    }

    const users = getUsersFromState();
    const user = users[userPubkey];
    if (!user) {
      logContext.api('User not found for update', {
        requestId,
        userPubkey
      });
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Update user fields
    const updateData = parse.data;
    Object.keys(updateData).forEach(key => {
      if (updateData[key as keyof typeof updateData] !== undefined) {
        (user as any)[key] = updateData[key as keyof typeof updateData];
      }
    });

    user.lastSeen = new Date().toISOString();
    
    // Save updated user
    users[userPubkey] = user;
    saveUsersToState(users);

    logContext.api('User profile updated successfully', {
      requestId,
      userPubkey,
      updatedFields: Object.keys(updateData)
    });

    res.json({
      success: true,
      message: 'User profile updated successfully',
      user
    });

  } catch (error) {
    logContext.error('Failed to update user profile', error, 'users');

    res.status(500).json({
      success: false,
      error: 'Failed to update user profile',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Get all users (for admin/debugging)
usersRouter.get('/', async (req: Request, res: Response) => {
  const requestId = `users_list_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  logContext.api('Getting users list', {
    requestId
  });

  try {
    const usersList = getUsersListFromState();
    const users = getUsersFromState();
    const userObjects = usersList.map((userPubkey: string) => users[userPubkey]).filter(Boolean);
    
    logContext.api('Users list retrieved successfully', {
      requestId,
      count: userObjects.length
    });

    res.json({
      success: true,
      count: userObjects.length,
      users: userObjects
    });

  } catch (error) {
    logContext.error('Failed to get users list', error, 'users');

    res.status(500).json({
      success: false,
      error: 'Failed to get users list',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export default usersRouter;
