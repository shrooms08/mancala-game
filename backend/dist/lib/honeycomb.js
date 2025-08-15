"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.badges = void 0;
exports.initContext = initContext;
exports.createProjectIfMissing = createProjectIfMissing;
exports.ensureProfilesTree = ensureProfilesTree;
exports.createUserAndProfile = createUserAndProfile;
exports.createMission = createMission;
const web3_js_1 = require("@solana/web3.js");
const dotenv_1 = require("dotenv");
const bs58_1 = __importDefault(require("bs58"));
const edge_client_1 = __importStar(require("@honeycomb-protocol/edge-client"));
const logger_1 = require("./logger");
(0, dotenv_1.config)();
const HONEYCOMB_RPC = process.env.HONEYCOMB_RPC || 'https://rpc.test.honeycombprotocol.com';
const HONEYCOMB_EDGE = process.env.HONEYCOMB_EDGE || 'https://edge.test.honeycombprotocol.com';
// Debug EdgeClient import
logger_1.logContext.debug('EdgeClient import details', {
    hasEdgeClient: !!edge_client_1.default,
    edgeClientType: typeof edge_client_1.default,
    edgeClientKeys: edge_client_1.default ? Object.keys(edge_client_1.default) : [],
    hasDefault: edge_client_1.default && 'default' in edge_client_1.default,
    hasCreate: edge_client_1.default && 'create' in edge_client_1.default,
    edgeUrl: HONEYCOMB_EDGE
}, 'honeycomb');
function initContext() {
    logger_1.logContext.honeycomb('Initializing Honeycomb context');
    const WALLET_PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY;
    if (!WALLET_PRIVATE_KEY) {
        logger_1.logContext.error('WALLET_PRIVATE_KEY environment variable is missing', null, 'honeycomb');
        throw new Error('WALLET_PRIVATE_KEY missing');
    }
    try {
        const secret = WALLET_PRIVATE_KEY.startsWith('[')
            ? Uint8Array.from(JSON.parse(WALLET_PRIVATE_KEY))
            : bs58_1.default.decode(WALLET_PRIVATE_KEY);
        const authority = web3_js_1.Keypair.fromSecretKey(secret);
        logger_1.logContext.honeycomb('Authority keypair created successfully', {
            publicKey: authority.publicKey.toString()
        });
        const connection = new web3_js_1.Connection(HONEYCOMB_RPC, 'confirmed');
        logger_1.logContext.honeycomb('Solana connection established', { rpc: HONEYCOMB_RPC });
        // Initialize EdgeClient with proper URL string
        let client;
        try {
            // Try different initialization patterns based on EdgeClient API
            if (typeof edge_client_1.default === 'function') {
                // If EdgeClient is a constructor function
                client = new edge_client_1.default(HONEYCOMB_EDGE);
            }
            else if (edge_client_1.default && typeof edge_client_1.default.create === 'function') {
                // If EdgeClient has a create method
                client = edge_client_1.default.create({ edgeUrl: HONEYCOMB_EDGE });
            }
            else if (edge_client_1.default && typeof edge_client_1.default.default === 'function') {
                // If EdgeClient is a default export
                client = new edge_client_1.default.default(HONEYCOMB_EDGE);
            }
            else {
                // Fallback: try to use as-is
                client = new edge_client_1.default(HONEYCOMB_EDGE);
            }
            logger_1.logContext.honeycomb('Honeycomb Edge client initialized successfully', {
                edgeUrl: HONEYCOMB_EDGE,
                clientType: typeof client,
                hasCreateProject: typeof client?.createCreateProjectTransaction === 'function'
            });
        }
        catch (clientError) {
            logger_1.logContext.error('Failed to initialize EdgeClient with standard patterns', clientError, 'honeycomb');
            // Try alternative initialization
            try {
                client = { edgeUrl: HONEYCOMB_EDGE };
                logger_1.logContext.warn('Using fallback client object - some operations may not work', {
                    edgeUrl: HONEYCOMB_EDGE
                }, 'honeycomb');
            }
            catch (fallbackError) {
                logger_1.logContext.error('All EdgeClient initialization attempts failed', fallbackError, 'honeycomb');
                throw new Error(`Failed to initialize Honeycomb Edge client: ${fallbackError instanceof Error ? fallbackError.message : String(fallbackError)}`);
            }
        }
        // Create a fallback client with mock methods if the real client doesn't have required methods
        if (!client.createCreateProjectTransaction) {
            logger_1.logContext.warn('Creating fallback client with mock methods for development', null, 'honeycomb');
            client = {
                edgeUrl: HONEYCOMB_EDGE,
                createCreateProjectTransaction: async (params) => {
                    logger_1.logContext.warn('Mock createCreateProjectTransaction called - Honeycomb integration not available', { params }, 'honeycomb');
                    throw new Error('Honeycomb Edge client not properly initialized. Check your @honeycomb-protocol/edge-client installation and configuration.');
                },
                createCreateProfilesTreeTransaction: async (params) => {
                    logger_1.logContext.warn('Mock createCreateProfilesTreeTransaction called - Honeycomb integration not available', { params }, 'honeycomb');
                    throw new Error('Honeycomb Edge client not properly initialized. Check your @honeycomb-protocol/edge-client installation and configuration.');
                },
                createCreateUserAndProfileTransaction: async (params) => {
                    logger_1.logContext.warn('Mock createCreateUserAndProfileTransaction called - Honeycomb integration not available', { params }, 'honeycomb');
                    throw new Error('Honeycomb Edge client not properly initialized. Check your @honeycomb-protocol/edge-client installation and configuration.');
                }
            };
        }
        return { client, connection, authority };
    }
    catch (error) {
        logger_1.logContext.error('Failed to initialize Honeycomb context', error, 'honeycomb');
        throw error;
    }
}
async function createProjectIfMissing(ctx) {
    let projectAddress = process.env.PROJECT_ADDRESS;
    if (projectAddress) {
        logger_1.logContext.honeycomb('Using existing project address', { projectAddress });
        return projectAddress;
    }
    logger_1.logContext.honeycomb('Creating new Honeycomb project');
    const name = process.env.PROJECT_NAME || 'Mancala Blockchain Game';
    const payer = ctx.authority.publicKey.toString();
    const authority = ctx.authority.publicKey.toString();
    logger_1.logContext.honeycomb('Project creation parameters', { name, payer, authority });
    try {
        const resp = await ctx.client.createCreateProjectTransaction({
            name,
            authority,
            payer,
            profileDataConfig: {
                achievements: ['Pioneer'],
                customDataFields: ['NFTs owned']
            }
        });
        logger_1.logContext.honeycomb('Project creation transaction response received', {
            hasResponse: !!resp,
            responseKeys: Object.keys(resp || {})
        });
        const { tx, project } = resp.createCreateProjectTransaction ?? resp;
        if (!tx || !project) {
            logger_1.logContext.error('Invalid project creation response', { resp }, 'honeycomb');
            throw new Error('Failed to get project creation tx');
        }
        logger_1.logContext.honeycomb('Project creation transaction details', {
            project,
            hasTransaction: !!tx,
            transactionKeys: Object.keys(tx || {})
        });
        const txBytes = Buffer.from(tx.transaction, 'base64');
        // Try different transaction deserialization methods
        let vtx;
        try {
            // First try standard deserialization
            vtx = web3_js_1.VersionedTransaction.deserialize(txBytes);
            logger_1.logContext.honeycomb('Transaction deserialized successfully with standard method', {
                version: vtx.message.version,
                numSignatures: vtx.signatures.length
            });
        }
        catch (deserializeError) {
            logger_1.logContext.warn('Standard transaction deserialization failed, trying alternative methods', {
                error: deserializeError instanceof Error ? deserializeError.message : String(deserializeError)
            }, 'honeycomb');
            try {
                // Try legacy transaction format
                const { Transaction } = require('@solana/web3.js');
                vtx = Transaction.from(txBytes);
                logger_1.logContext.honeycomb('Transaction deserialized with legacy method', {
                    hasSignatures: !!vtx.signatures
                });
            }
            catch (legacyError) {
                logger_1.logContext.error('All transaction deserialization methods failed', {
                    standardError: deserializeError instanceof Error ? deserializeError.message : String(deserializeError),
                    legacyError: legacyError instanceof Error ? legacyError.message : String(legacyError),
                    transactionSize: txBytes.length,
                    transactionPreview: txBytes.slice(0, 50).toString('hex')
                }, 'honeycomb');
                // WORKAROUND: For unsupported transaction versions, skip processing and return project address
                // This allows the server to continue functioning while we wait for Solana Web3.js to support newer formats
                if (deserializeError instanceof Error && deserializeError.message.includes('version 67')) {
                    logger_1.logContext.warn('Unsupported transaction version 67 detected - using workaround', {
                        project,
                        transactionSize: txBytes.length,
                        note: 'Transaction processing skipped - project creation may not be fully confirmed on-chain'
                    }, 'honeycomb');
                    // Store the project address but warn about incomplete processing
                    process.env.PROJECT_ADDRESS = project;
                    logger_1.logContext.warn('Project address stored but transaction not processed - blockchain integration limited', {
                        project,
                        reason: 'Unsupported transaction format version 67'
                    }, 'honeycomb');
                    return project;
                }
                throw new Error(`Failed to deserialize transaction: ${deserializeError instanceof Error ? deserializeError.message : String(deserializeError)}`);
            }
        }
        vtx.sign([ctx.authority]);
        logger_1.logContext.honeycomb('Sending project creation transaction');
        const sig = await ctx.connection.sendTransaction(vtx, { skipPreflight: false });
        logger_1.logContext.honeycomb('Project creation transaction sent', { signature: sig });
        await ctx.connection.confirmTransaction({ signature: sig, ...tx });
        logger_1.logContext.honeycomb('Project creation transaction confirmed', { signature: sig });
        logger_1.logContext.honeycomb('Project created successfully', { project, signature: sig });
        process.env.PROJECT_ADDRESS = project; // keep in memory
        return project;
    }
    catch (error) {
        logger_1.logContext.error('Failed to create project', error, 'honeycomb');
        throw error;
    }
}
async function ensureProfilesTree(ctx, project) {
    logger_1.logContext.honeycomb('Ensuring profiles tree exists', { project });
    try {
        const payer = ctx.authority.publicKey.toString();
        const resp = await ctx.client.createCreateProfilesTreeTransaction({
            authority: payer,
            project,
            payer
            // Removed treeConfig as it's not supported by the current GraphQL schema
        });
        const { tx } = resp.createCreateProfilesTreeTransaction ?? resp;
        if (!tx) {
            logger_1.logContext.honeycomb('Profiles tree already exists, skipping creation');
            return; // assume exists
        }
        logger_1.logContext.honeycomb('Creating profiles tree transaction', {
            hasTransaction: !!tx,
            transactionKeys: Object.keys(tx || {})
        });
        const txBytes = Buffer.from(tx.transaction, 'base64');
        const vtx = web3_js_1.VersionedTransaction.deserialize(txBytes);
        vtx.sign([ctx.authority]);
        logger_1.logContext.honeycomb('Sending profiles tree creation transaction');
        const sig = await ctx.connection.sendTransaction(vtx, { skipPreflight: false });
        logger_1.logContext.honeycomb('Profiles tree transaction sent', { signature: sig });
        await ctx.connection.confirmTransaction({ signature: sig, ...tx });
        logger_1.logContext.honeycomb('Profiles tree created successfully', { signature: sig });
    }
    catch (error) {
        // WORKAROUND: If the GraphQL API requires unsupported parameters, skip profiles tree creation
        // This allows the server to continue functioning while we resolve the API compatibility issues
        if (error instanceof Error && error.message.includes('TreeSetupConfig')) {
            logger_1.logContext.warn('Profiles tree creation failed due to API compatibility - using workaround', {
                project,
                error: error.message,
                note: 'Profiles tree creation skipped - user profile creation may not work until API compatibility is resolved'
            }, 'honeycomb');
            // Return successfully to allow the server to continue
            return;
        }
        logger_1.logContext.error('Failed to ensure profiles tree', error, 'honeycomb');
        throw error;
    }
}
async function createUserAndProfile(ctx, userPubkey) {
    logger_1.logContext.honeycomb('Creating user and profile', { userPubkey });
    try {
        const project = process.env.PROJECT_ADDRESS;
        const payer = ctx.authority.publicKey.toString();
        logger_1.logContext.honeycomb('User profile creation parameters', { project, payer, userPubkey });
        const resp = await ctx.client.createCreateUserAndProfileTransaction({
            project,
            user: userPubkey,
            payer
        });
        const { tx, profile } = resp.createCreateUserAndProfileTransaction ?? resp;
        logger_1.logContext.honeycomb('User profile creation response', {
            hasTransaction: !!tx,
            hasProfile: !!profile,
            profile
        });
        const txBytes = Buffer.from(tx.transaction, 'base64');
        const vtx = web3_js_1.VersionedTransaction.deserialize(txBytes);
        vtx.sign([ctx.authority]);
        logger_1.logContext.honeycomb('Sending user profile creation transaction');
        const sig = await ctx.connection.sendTransaction(vtx, { skipPreflight: false });
        logger_1.logContext.honeycomb('User profile transaction sent', { signature: sig });
        await ctx.connection.confirmTransaction({ signature: sig, ...tx });
        logger_1.logContext.honeycomb('User profile created successfully', { profile, signature: sig });
        return { profile, sig };
    }
    catch (error) {
        logger_1.logContext.error('Failed to create user and profile', error, 'honeycomb');
        throw error;
    }
}
async function createMission(ctx, args) {
    logger_1.logContext.honeycomb('Creating mission (placeholder)', { missionArgs: args });
    // Placeholder: depends on missions API in Honeycomb docs
    logger_1.logContext.warn('Mission creation not yet implemented - waiting for Honeycomb API', { args }, 'honeycomb');
}
exports.badges = { BadgesCondition: edge_client_1.BadgesCondition };
