import dotenv from 'dotenv';

// Load .env file if it exists
dotenv.config({ path: '../.env' });

export const CHAINS = {
    testnets: {
        1: {
            name: "Rari Testnet",
            rpc: process.env.RARI_TESTNET_RPC || "https://rari-testnet.calderachain.xyz/http"
        },
        2: {
            name: "LogX Testnet",
            rpc: process.env.LOGX_TESTNET_RPC || "https://kartel-testnet.alt.technology"
        },
        3: {
            name: "Appchain Testnet",
            rpc: process.env.APPCHAIN_TESTNET_RPC || "https://appchaintestnet.rpc.caldera.xyz"
        },
        4: {
            name: "NodeOps Testnet",
            rpc: process.env.NODEOPS_TESTNET_RPC || "https://nodeops-orchestrator-network.calderachain.xyz/http"
        },
        5: {
            name: "Apechain Testnet",
            rpc: process.env.APECHAIN_TESTNET_RPC || "https://apechain-testnet.rpc.caldera.xyz/http"
        },
        6: {
            name: "Rufus Testnet",
            rpc: process.env.RUFUS_TESTNET_RPC || "https://rufus-sepolia-testnet.rpc.caldera.xyz/http"
        },
        7: {
            name: "T3rn Testnet",
            rpc: process.env.T3RN_TESTNET_RPC || "https://brn-testnet.rpc.caldera.xyz/http"
        },
        8: {
            name: "Huddle01",
            rpc: process.env.HUDDLE01_RPC || "https://huddle-testnet.rpc.caldera.xyz/http"
        },
        9: {
            name: "Custom Network",
            rpc: process.env.CUSTOM_RPC || "https://your-custom-rpc-endpoint.com"
        }
    },
    mainnets: {}
};