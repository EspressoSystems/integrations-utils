import fs from 'fs';

// Load .env file if it exists
if (fs.existsSync('../.env')) {
    fs.readFileSync('../.env', 'utf8')
        .split('\n')
        .forEach(line => {
            const [key, value] = line.split('=');
            if (key && value) process.env[key] = value;
        });
}

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
        }
    },
    mainnets: {
        4: {
            name: "Rari Mainnet",
            rpc: process.env.RARI_MAINNET_RPC || "https://rari.calderachain.xyz/http"
        },
        5: {
            name: "LogX Mainnet",
            rpc: process.env.LOGX_MAINNET_RPC || "https://vzjuxmhfn70kgnlds27h.alt.technology"
        },
        6: {
            name: "Appchain Mainnet", 
            rpc: process.env.APPCHAIN_MAINNET_RPC || "https://appchain.calderachain.xyz/http"
        },
        7: {
            name: "Molten Mainnet",
            rpc: process.env.MOLTEN_MAINNET_RPC || "https://molten.calderachain.xyz/http"
        }
    }
};