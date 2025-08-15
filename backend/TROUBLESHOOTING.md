# Troubleshooting Guide

This guide helps resolve common issues with the Mancala backend server.

## 🚨 EdgeClient Initialization Errors

### Error: `[Network] Failed to parse URL from [object Object]`

This error typically occurs when the `@honeycomb-protocol/edge-client` package is not properly initialized.

#### Symptoms
- Server starts but fails to bootstrap Honeycomb project
- Error messages about Edge client initialization
- Blockchain features not working

#### Root Causes
1. **Package Installation Issues**: The EdgeClient package may not be properly installed
2. **Version Compatibility**: Package version may be incompatible with current Node.js version
3. **Import Issues**: The package may have changed its export structure
4. **Environment Configuration**: Invalid URLs in environment variables

#### Solutions

##### 1. Check Package Installation
```bash
# Verify the package is installed
npm list @honeycomb-protocol/edge-client

# If not installed or showing errors, reinstall
npm uninstall @honeycomb-protocol/edge-client
npm install @honeycomb-protocol/edge-client
```

##### 2. Check Package Version
```bash
# Check available versions
npm view @honeycomb-protocol/edge-client versions

# Install a specific version if needed
npm install @honeycomb-protocol/edge-client@<version>
```

##### 3. Verify Environment Variables
Check your `.env` file:
```bash
# These should be valid URLs
HONEYCOMB_RPC=https://rpc.test.honeycombprotocol.com
HONEYCOMB_EDGE=https://edge.test.honeycombprotocol.com
```

##### 4. Test EdgeClient Manually
Create a test file to verify the package works:
```typescript
// test-edge-client.ts
import EdgeClient from '@honeycomb-protocol/edge-client';

console.log('EdgeClient type:', typeof EdgeClient);
console.log('EdgeClient keys:', Object.keys(EdgeClient || {}));
console.log('Has default:', 'default' in (EdgeClient || {}));
console.log('Has create:', 'create' in (EdgeClient || {}));

try {
  const client = new EdgeClient('https://edge.test.honeycombprotocol.com');
  console.log('Client created successfully:', typeof client);
} catch (error) {
  console.error('Failed to create client:', error);
}
```

Run with: `npx ts-node test-edge-client.ts`

##### 5. Alternative Package Sources
If the official package continues to have issues:
```bash
# Try installing from GitHub if available
npm install github:honeycomb-protocol/edge-client

# Or use a different package manager
yarn add @honeycomb-protocol/edge-client
```

## 🔧 Other Common Issues

### Server Won't Start

#### Port Already in Use
```bash
# Check what's using the port
lsof -i :8080

# Kill the process or change port in .env
PORT=8081 npm run dev
```

#### Missing Environment Variables
```bash
# Ensure .env file exists and has required values
cp .env.example .env
# Edit .env and add your WALLET_PRIVATE_KEY
```

### Build Errors

#### TypeScript Compilation Issues
```bash
# Clean and rebuild
npm run clean
npm run rebuild

# Check TypeScript version compatibility
npx tsc --version
```

#### Dependency Issues
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

## 📊 Debugging Tips

### Enable Debug Logging
```bash
# Start with debug level
npm run logs:debug

# Or set environment variable
LOG_LEVEL=debug npm run dev
```

### Check Logs for Specific Contexts
The logging system uses different contexts. Look for:
- `honeycomb` - Blockchain operations
- `server` - Server lifecycle
- `api` - HTTP requests
- `game` - Game operations
- `state` - Data persistence

### Monitor Network Requests
```bash
# Check if Honeycomb endpoints are reachable
curl -v https://edge.test.honeycombprotocol.com
curl -v https://rpc.test.honeycombprotocol.com
```

## 🆘 Getting Help

### Check Logs First
Always check the server logs first - they contain detailed error information and context.

### Common Log Patterns
- **EdgeClient errors**: Look for "honeycomb" context logs
- **Network issues**: Check "http" context logs
- **State problems**: Review "state" context logs

### Environment Information
When reporting issues, include:
- Node.js version: `node --version`
- NPM version: `npm --version`
- Package versions: `npm list`
- Environment: `cat .env` (remove sensitive data)
- Error logs: Copy relevant log sections

### Next Steps
If the EdgeClient issue persists:
1. Check the [Honeycomb Protocol documentation](https://docs.honeycombprotocol.com/)
2. Verify your Solana wallet configuration
3. Ensure you're using the correct testnet/mainnet endpoints
4. Consider using a different Honeycomb client library if available

## 🚀 Development Mode

For development without full Honeycomb integration:
```bash
# Start with mock client (blockchain features disabled)
npm run dev

# The server will start with helpful error messages
# Use the /health endpoint to verify basic functionality
curl http://localhost:8080/health
```

This allows you to develop and test other features while resolving the blockchain integration issues.
