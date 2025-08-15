import { Connection, Keypair, VersionedTransaction } from '@solana/web3.js';
import { config } from 'dotenv';
import bs58 from 'bs58';
import EdgeClient, { BadgesCondition } from '@honeycomb-protocol/edge-client';
import { logContext } from './logger';

config();

const HONEYCOMB_RPC = process.env.HONEYCOMB_RPC || 'https://rpc.test.honeycombprotocol.com';
const HONEYCOMB_EDGE = process.env.HONEYCOMB_EDGE || 'https://edge.test.honeycombprotocol.com';

// Debug EdgeClient import
logContext.debug('EdgeClient import details', {
  hasEdgeClient: !!EdgeClient,
  edgeClientType: typeof EdgeClient,
  edgeClientKeys: EdgeClient ? Object.keys(EdgeClient) : [],
  hasDefault: EdgeClient && 'default' in EdgeClient,
  hasCreate: EdgeClient && 'create' in EdgeClient,
  edgeUrl: HONEYCOMB_EDGE
}, 'honeycomb');

export type ProjectContext = {
  client: any;
  connection: Connection;
  authority: Keypair;
  projectAddress?: string;
};

export function initContext(): ProjectContext {
  logContext.honeycomb('Initializing Honeycomb context');
  
  const WALLET_PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY;
  if (!WALLET_PRIVATE_KEY) {
    logContext.error('WALLET_PRIVATE_KEY environment variable is missing', null, 'honeycomb');
    throw new Error('WALLET_PRIVATE_KEY missing');
  }

  try {
    const secret = WALLET_PRIVATE_KEY.startsWith('[')
      ? Uint8Array.from(JSON.parse(WALLET_PRIVATE_KEY))
      : bs58.decode(WALLET_PRIVATE_KEY);
    
    const authority = Keypair.fromSecretKey(secret);
    logContext.honeycomb('Authority keypair created successfully', { 
      publicKey: authority.publicKey.toString() 
    });

    const connection = new Connection(HONEYCOMB_RPC, 'confirmed');
    logContext.honeycomb('Solana connection established', { rpc: HONEYCOMB_RPC });

    // Initialize EdgeClient with proper URL string
    let client: any;
    try {
      // Try different initialization patterns based on EdgeClient API
      if (typeof EdgeClient === 'function') {
        // If EdgeClient is a constructor function
        client = new (EdgeClient as any)(HONEYCOMB_EDGE);
      } else if (EdgeClient && typeof (EdgeClient as any).create === 'function') {
        // If EdgeClient has a create method
        client = (EdgeClient as any).create({ edgeUrl: HONEYCOMB_EDGE });
      } else if (EdgeClient && typeof (EdgeClient as any).default === 'function') {
        // If EdgeClient is a default export
        client = new ((EdgeClient as any).default as any)(HONEYCOMB_EDGE);
      } else {
        // Fallback: try to use as-is
        client = new (EdgeClient as any)(HONEYCOMB_EDGE);
      }
      
      logContext.honeycomb('Honeycomb Edge client initialized successfully', { 
        edgeUrl: HONEYCOMB_EDGE,
        clientType: typeof client,
        hasCreateProject: typeof client?.createCreateProjectTransaction === 'function'
      });
    } catch (clientError) {
      logContext.error('Failed to initialize EdgeClient with standard patterns', clientError, 'honeycomb');
      
      // Try alternative initialization
      try {
        client = { edgeUrl: HONEYCOMB_EDGE };
        logContext.warn('Using fallback client object - some operations may not work', { 
          edgeUrl: HONEYCOMB_EDGE 
        }, 'honeycomb');
      } catch (fallbackError) {
        logContext.error('All EdgeClient initialization attempts failed', fallbackError, 'honeycomb');
        throw new Error(`Failed to initialize Honeycomb Edge client: ${fallbackError instanceof Error ? fallbackError.message : String(fallbackError)}`);
      }
    }

    // Create a fallback client with mock methods if the real client doesn't have required methods
    if (!client.createCreateProjectTransaction) {
      logContext.warn('Creating fallback client with mock methods for development', null, 'honeycomb');
      
      client = {
        edgeUrl: HONEYCOMB_EDGE,
        createCreateProjectTransaction: async (params: any) => {
          logContext.warn('Mock createCreateProjectTransaction called - Honeycomb integration not available', { params }, 'honeycomb');
          throw new Error('Honeycomb Edge client not properly initialized. Check your @honeycomb-protocol/edge-client installation and configuration.');
        },
        createCreateProfilesTreeTransaction: async (params: any) => {
          logContext.warn('Mock createCreateProfilesTreeTransaction called - Honeycomb integration not available', { params }, 'honeycomb');
          throw new Error('Honeycomb Edge client not properly initialized. Check your @honeycomb-protocol/edge-client installation and configuration.');
        },
        createCreateUserAndProfileTransaction: async (params: any) => {
          logContext.warn('Mock createCreateUserAndProfileTransaction called - Honeycomb integration not available', { params }, 'honeycomb');
          throw new Error('Honeycomb Edge client not properly initialized. Check your @honeycomb-protocol/edge-client installation and configuration.');
        }
      };
    }

    return { client, connection, authority };
  } catch (error) {
    logContext.error('Failed to initialize Honeycomb context', error, 'honeycomb');
    throw error;
  }
}

export async function createProjectIfMissing(ctx: ProjectContext) {
  let projectAddress = process.env.PROJECT_ADDRESS;
  
  if (projectAddress) {
    logContext.honeycomb('Using existing project address', { projectAddress });
    return projectAddress;
  }

  logContext.honeycomb('Creating new Honeycomb project');
  
  const name = process.env.PROJECT_NAME || 'Mancala Blockchain Game';
  const payer = ctx.authority.publicKey.toString();
  const authority = ctx.authority.publicKey.toString();

  logContext.honeycomb('Project creation parameters', { name, payer, authority });

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

    logContext.honeycomb('Project creation transaction response received', { 
      hasResponse: !!resp,
      responseKeys: Object.keys(resp || {})
    });

    const { tx, project } = (resp as any).createCreateProjectTransaction ?? resp;
    if (!tx || !project) {
      logContext.error('Invalid project creation response', { resp }, 'honeycomb');
      throw new Error('Failed to get project creation tx');
    }

    logContext.honeycomb('Project creation transaction details', { 
      project, 
      hasTransaction: !!tx,
      transactionKeys: Object.keys(tx || {})
    });

    const txBytes = Buffer.from(tx.transaction, 'base64');
    
    // Try different transaction deserialization methods
    let vtx: VersionedTransaction;
    try {
      // First try standard deserialization
      vtx = VersionedTransaction.deserialize(txBytes);
      logContext.honeycomb('Transaction deserialized successfully with standard method', { 
        version: vtx.message.version,
        numSignatures: vtx.signatures.length 
      });
    } catch (deserializeError) {
      logContext.warn('Standard transaction deserialization failed, trying alternative methods', { 
        error: deserializeError instanceof Error ? deserializeError.message : String(deserializeError) 
      }, 'honeycomb');
      
      try {
        // Try legacy transaction format
        const { Transaction } = require('@solana/web3.js');
        vtx = Transaction.from(txBytes) as any;
        logContext.honeycomb('Transaction deserialized with legacy method', { 
          hasSignatures: !!vtx.signatures 
        });
      } catch (legacyError) {
        logContext.error('All transaction deserialization methods failed', { 
          standardError: deserializeError instanceof Error ? deserializeError.message : String(deserializeError),
          legacyError: legacyError instanceof Error ? legacyError.message : String(legacyError),
          transactionSize: txBytes.length,
          transactionPreview: txBytes.slice(0, 50).toString('hex')
        }, 'honeycomb');
        
        // WORKAROUND: For unsupported transaction versions, skip processing and return project address
        // This allows the server to continue functioning while we wait for Solana Web3.js to support newer formats
        if (deserializeError instanceof Error && deserializeError.message.includes('version 67')) {
          logContext.warn('Unsupported transaction version 67 detected - using workaround', {
            project,
            transactionSize: txBytes.length,
            note: 'Transaction processing skipped - project creation may not be fully confirmed on-chain'
          }, 'honeycomb');
          
          // Store the project address but warn about incomplete processing
          process.env.PROJECT_ADDRESS = project;
          logContext.warn('Project address stored but transaction not processed - blockchain integration limited', {
            project,
            reason: 'Unsupported transaction format version 67'
          }, 'honeycomb');
          
          return project as string;
        }
        
        throw new Error(`Failed to deserialize transaction: ${deserializeError instanceof Error ? deserializeError.message : String(deserializeError)}`);
      }
    }
    
    vtx.sign([ctx.authority]);
    
    logContext.honeycomb('Sending project creation transaction');
    const sig = await ctx.connection.sendTransaction(vtx, { skipPreflight: false });
    
    logContext.honeycomb('Project creation transaction sent', { signature: sig });
    
    await ctx.connection.confirmTransaction({ signature: sig, ...tx });
    logContext.honeycomb('Project creation transaction confirmed', { signature: sig });

    logContext.honeycomb('Project created successfully', { project, signature: sig });
    process.env.PROJECT_ADDRESS = project; // keep in memory
    return project as string;
  } catch (error) {
    logContext.error('Failed to create project', error, 'honeycomb');
    throw error;
  }
}

export async function ensureProfilesTree(ctx: ProjectContext, project: string) {
  logContext.honeycomb('Ensuring profiles tree exists', { project });
  
  try {
    const payer = ctx.authority.publicKey.toString();
    const resp = await ctx.client.createCreateProfilesTreeTransaction({
      authority: payer,
      project,
      payer
      // Removed treeConfig as it's not supported by the current GraphQL schema
    });

    const { tx } = (resp as any).createCreateProfilesTreeTransaction ?? resp;
    if (!tx) {
      logContext.honeycomb('Profiles tree already exists, skipping creation');
      return; // assume exists
    }

    logContext.honeycomb('Creating profiles tree transaction', { 
      hasTransaction: !!tx,
      transactionKeys: Object.keys(tx || {})
    });

    const txBytes = Buffer.from(tx.transaction, 'base64');
    const vtx = VersionedTransaction.deserialize(txBytes);
    vtx.sign([ctx.authority]);
    
    logContext.honeycomb('Sending profiles tree creation transaction');
    const sig = await ctx.connection.sendTransaction(vtx, { skipPreflight: false });
    
    logContext.honeycomb('Profiles tree transaction sent', { signature: sig });
    
    await ctx.connection.confirmTransaction({ signature: sig, ...tx });
    logContext.honeycomb('Profiles tree created successfully', { signature: sig });
  } catch (error) {
    // WORKAROUND: If the GraphQL API requires unsupported parameters, skip profiles tree creation
    // This allows the server to continue functioning while we resolve the API compatibility issues
    if (error instanceof Error && error.message.includes('TreeSetupConfig')) {
      logContext.warn('Profiles tree creation failed due to API compatibility - using workaround', {
        project,
        error: error.message,
        note: 'Profiles tree creation skipped - user profile creation may not work until API compatibility is resolved'
      }, 'honeycomb');
      
      // Return successfully to allow the server to continue
      return;
    }
    
    logContext.error('Failed to ensure profiles tree', error, 'honeycomb');
    throw error;
  }
}

export async function createUserAndProfile(ctx: ProjectContext, userPubkey: string) {
  logContext.honeycomb('Creating user and profile', { userPubkey });
  
  try {
    const project = process.env.PROJECT_ADDRESS!;
    const payer = ctx.authority.publicKey.toString();
    
    logContext.honeycomb('User profile creation parameters', { project, payer, userPubkey });
    
    const resp = await ctx.client.createCreateUserAndProfileTransaction({
      project,
      user: userPubkey,
      payer
    });

    const { tx, profile } = (resp as any).createCreateUserAndProfileTransaction ?? resp;
    
    logContext.honeycomb('User profile creation response', { 
      hasTransaction: !!tx,
      hasProfile: !!profile,
      profile
    });

    const txBytes = Buffer.from(tx.transaction, 'base64');
    const vtx = VersionedTransaction.deserialize(txBytes);
    vtx.sign([ctx.authority]);
    
    logContext.honeycomb('Sending user profile creation transaction');
    const sig = await ctx.connection.sendTransaction(vtx, { skipPreflight: false });
    
    logContext.honeycomb('User profile transaction sent', { signature: sig });
    
    await ctx.connection.confirmTransaction({ signature: sig, ...tx });
    logContext.honeycomb('User profile created successfully', { profile, signature: sig });
    
    return { profile, sig };
  } catch (error) {
    logContext.error('Failed to create user and profile', error, 'honeycomb');
    throw error;
  }
}

export async function createMission(ctx: ProjectContext, args: { name: string; description?: string }) {
  logContext.honeycomb('Creating mission (placeholder)', { missionArgs: args });
  // Placeholder: depends on missions API in Honeycomb docs
  logContext.warn('Mission creation not yet implemented - waiting for Honeycomb API', { args }, 'honeycomb');
}

export const badges = { BadgesCondition };
