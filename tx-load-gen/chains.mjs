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
        rari: {
            name: "Rari",
            rpc: process.env.RARI_TESTNET_RPC || "https://rari-testnet.calderachain.xyz/http"
        },
        logx: {
            name: "LogX", 
            rpc: process.env.LOGX_TESTNET_RPC || "https://kartel-testnet.alt.technology"
        },
        appchain: {
            name: "Appchain",
            rpc: process.env.APPCHAIN_TESTNET_RPC || "https://appchaintestnet.rpc.caldera.xyz"
        }
    },
    mainnets: {
        rari: {
            name: "Rari",
            rpc: process.env.RARI_MAINNET_RPC || "https://rari.calderachain.xyz/http"
        },
        logx: {
            name: "LogX",
            rpc: process.env.LOGX_MAINNET_RPC || "https://vzjuxmhfn70kgnlds27h.alt.technology"
        },
        appchain: {
            name: "Appchain", 
            rpc: process.env.APPCHAIN_MAINNET_RPC || "https://appchain.calderachain.xyz/http"
        },
        molten: {
            name: "Molten",
            rpc: process.env.MOLTEN_MAINNET_RPC || "https://molten.calderachain.xyz/http"
        }
    }
};