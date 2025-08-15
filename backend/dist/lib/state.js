"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadState = loadState;
exports.saveState = saveState;
exports.getStateValue = getStateValue;
exports.setStateValue = setStateValue;
exports.clearState = clearState;
exports.getStateInfo = getStateInfo;
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const logger_1 = require("./logger");
const statePath = path_1.default.resolve(process.cwd(), 'data/state.json');
function ensureDir() {
    const dir = path_1.default.dirname(statePath);
    if (!fs_1.default.existsSync(dir)) {
        logger_1.logContext.debug('Creating state directory', { dir });
        fs_1.default.mkdirSync(dir, { recursive: true });
    }
}
function loadState() {
    try {
        if (!fs_1.default.existsSync(statePath)) {
            logger_1.logContext.debug('State file does not exist, returning empty state', { statePath });
            return {};
        }
        const raw = fs_1.default.readFileSync(statePath, 'utf8');
        const state = JSON.parse(raw);
        logger_1.logContext.debug('State loaded successfully', {
            statePath,
            stateKeys: Object.keys(state),
            fileSize: raw.length
        });
        return state;
    }
    catch (error) {
        logger_1.logContext.error('Failed to load state from file', error, 'state');
        // Return empty state on error to prevent crashes
        logger_1.logContext.warn('Returning empty state due to load error', null, 'state');
        return {};
    }
}
function saveState(update) {
    try {
        ensureDir();
        const current = loadState();
        const next = { ...current, ...update };
        logger_1.logContext.debug('Saving state update', {
            statePath,
            currentKeys: Object.keys(current),
            updateKeys: Object.keys(update),
            nextKeys: Object.keys(next)
        });
        const jsonString = JSON.stringify(next, null, 2);
        fs_1.default.writeFileSync(statePath, jsonString);
        logger_1.logContext.debug('State saved successfully', {
            statePath,
            fileSize: jsonString.length,
            updatedKeys: Object.keys(update)
        });
        return next;
    }
    catch (error) {
        logger_1.logContext.error('Failed to save state to file', error, 'state');
        // Return current state on error to prevent data loss
        logger_1.logContext.warn('State save failed, returning current state', null, 'state');
        return loadState();
    }
}
// Utility function to get specific state values
function getStateValue(key) {
    const state = loadState();
    const value = state[key];
    logger_1.logContext.debug('State value retrieved', { key, hasValue: value !== undefined });
    return value;
}
// Utility function to set specific state values
function setStateValue(key, value) {
    logger_1.logContext.debug('Setting state value', { key, value });
    const current = loadState();
    current[key] = value;
    saveState(current);
}
// Utility function to clear all state
function clearState() {
    try {
        if (fs_1.default.existsSync(statePath)) {
            fs_1.default.unlinkSync(statePath);
            logger_1.logContext.debug('State file deleted', { statePath });
        }
        logger_1.logContext.debug('State cleared successfully');
    }
    catch (error) {
        logger_1.logContext.error('Failed to clear state', error, 'state');
    }
}
// Utility function to get state file info
function getStateInfo() {
    try {
        const exists = fs_1.default.existsSync(statePath);
        const stats = exists ? fs_1.default.statSync(statePath) : null;
        const info = {
            exists,
            size: stats?.size,
            path: statePath
        };
        logger_1.logContext.debug('State file info retrieved', info);
        return info;
    }
    catch (error) {
        logger_1.logContext.error('Failed to get state file info', error, 'state');
        return { exists: false, path: statePath };
    }
}
