import fs from 'fs';
import path from 'path';
import { logContext } from './logger';

type State = {
  projectAddress?: string;
  xpResourceAddress?: string;
  characterModelAddress?: string;
  profilesByUser?: Record<string, string>;
  charactersByUser?: Record<string, string>;
  users?: Record<string, any>;
  usersList?: string[];
};

const statePath = path.resolve(process.cwd(), 'data/state.json');

function ensureDir() {
  const dir = path.dirname(statePath);
  if (!fs.existsSync(dir)) {
    logContext.debug('Creating state directory', { dir });
    fs.mkdirSync(dir, { recursive: true });
  }
}

export function loadState(): State {
  try {
    if (!fs.existsSync(statePath)) {
      logContext.debug('State file does not exist, returning empty state', { statePath });
      return {};
    }

    const raw = fs.readFileSync(statePath, 'utf8');
    const state = JSON.parse(raw);
    
    logContext.debug('State loaded successfully', { 
      statePath,
      stateKeys: Object.keys(state),
      fileSize: raw.length
    });
    
    return state;
  } catch (error) {
    logContext.error('Failed to load state from file', error, 'state');
    
    // Return empty state on error to prevent crashes
    logContext.warn('Returning empty state due to load error', null, 'state');
    return {};
  }
}

export function saveState(update: Partial<State>): State {
  try {
    ensureDir();
    const current = loadState();
    const next = { ...current, ...update };
    
    logContext.debug('Saving state update', { 
      statePath,
      currentKeys: Object.keys(current),
      updateKeys: Object.keys(update),
      nextKeys: Object.keys(next)
    });
    
    const jsonString = JSON.stringify(next, null, 2);
    fs.writeFileSync(statePath, jsonString);
    
    logContext.debug('State saved successfully', { 
      statePath,
      fileSize: jsonString.length,
      updatedKeys: Object.keys(update)
    });
    
    return next;
  } catch (error) {
    logContext.error('Failed to save state to file', error, 'state');
    
    // Return current state on error to prevent data loss
    logContext.warn('State save failed, returning current state', null, 'state');
    return loadState();
  }
}

// Utility function to get specific state values
export function getStateValue<K extends keyof State>(key: K): State[K] | undefined {
  const state = loadState();
  const value = state[key];
  
  logContext.debug('State value retrieved', { key, hasValue: value !== undefined });
  
  return value;
}

// Utility function to set specific state values
export function setStateValue<K extends keyof State>(key: K, value: State[K]): void {
  logContext.debug('Setting state value', { key, value });
  
  const current = loadState();
  current[key] = value;
  saveState(current);
}

// Utility function to clear all state
export function clearState(): void {
  try {
    if (fs.existsSync(statePath)) {
      fs.unlinkSync(statePath);
      logContext.debug('State file deleted', { statePath });
    }
    
    logContext.debug('State cleared successfully');
  } catch (error) {
    logContext.error('Failed to clear state', error, 'state');
  }
}

// Utility function to get state file info
export function getStateInfo(): { exists: boolean; size?: number; path: string } {
  try {
    const exists = fs.existsSync(statePath);
    const stats = exists ? fs.statSync(statePath) : null;
    
    const info = {
      exists,
      size: stats?.size,
      path: statePath
    };
    
    logContext.debug('State file info retrieved', info);
    return info;
  } catch (error) {
    logContext.error('Failed to get state file info', error, 'state');
    return { exists: false, path: statePath };
  }
}
