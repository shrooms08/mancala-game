# Godot Autoload Setup Guide

## How to Add Autoloads in Godot

1. **Open Project Settings** in Godot
   - Go to `Project` → `Project Settings`
   - Or press `Ctrl+Shift+O`

2. **Go to Autoload Tab**
   - Click on the `Autoload` tab in the Project Settings

3. **Add the Required Autoloads**

   Add these autoloads in this exact order:

   | Node Name | Path | Singleton |
   |-----------|------|-----------|
   | `GameGlobals` | `res://Script/GameGlobals.gd` | ✅ |
   | `GameProgressTracker` | `res://Script/GameProgressTracker.gd` | ✅ |
   | `HoneycombManager` | `res://Script/HoneycombManager.gd` | ✅ |
   | `BlockchainManager` | `res://Script/BlockchainManager.gd` | ✅ |

4. **Steps to Add Each Autoload:**
   - Click the folder icon next to "Path"
   - Navigate to `Script/` folder
   - Select the `.gd` file
   - Click "Add" button
   - Make sure "Singleton" is checked
   - Repeat for all 4 autoloads

5. **Verify Setup:**
   - All 4 autoloads should appear in the list
   - The order should be: GameGlobals, GameProgressTracker, HoneycombManager, BlockchainManager
   - All should have the "Singleton" checkbox checked

6. **Save and Restart:**
   - Click "OK" to save Project Settings
   - Restart the Godot editor
   - Run the game again

## Expected Console Output After Setup:

```
GameGlobals initialized
GameProgressTracker initialized
Honeycomb Manager initialized - Backend Mode
Backend URL configured: http://localhost:8080
Connecting to backend at: http://localhost:8080
BlockchainManager initialized
```

## Troubleshooting:

If you still see "❌ Progress tracker not available":

1. **Check Autoload Order**: Make sure GameProgressTracker is loaded before other scripts
2. **Verify File Paths**: Ensure all script files exist in the Script/ folder
3. **Check for Errors**: Look for any script errors in the console
4. **Restart Godot**: Sometimes a restart is needed after adding autoloads

## File Structure Check:

Make sure you have these files:
```
Script/
├── GameGlobals.gd
├── GameProgressTracker.gd
├── HoneycombManager.gd
├── BlockchainManager.gd
├── BackendConfig.gd
└── play_game.gd
```
