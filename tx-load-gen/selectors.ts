import { createRequire } from 'module';
import type { Chain, Chains } from './types.ts';

const require = createRequire(import.meta.url);
const readline = require('readline');

export const selectDataSize = (): Promise<number> => {
    return new Promise((resolve) => {
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('Enter data size in KB (max 64): ', (answer: string) => {
            rl.close();
            const size = Math.min(parseInt(answer) || 1, 64);
            resolve(size);
        });
    });
};

export const selectChain = (chains: Chains): Promise<Chain> => {
    return new Promise((resolve) => {
        console.log("\n");
        console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        console.log("");
        console.log("🌐 TESTNET NETWORKS");
        console.log("");
        Object.entries(chains.testnets).forEach(([key, chain]) => {
            console.log(`   ${key}.  ${chain.name}`);
            console.log(`       └─ ${chain.rpc}`);
        });
        console.log("");
        console.log("🚀 MAINNET NETWORKS");
        console.log("");
        Object.entries(chains.mainnets).forEach(([key, chain]) => {
            console.log(`   ${key}.  ${chain.name}`);
            console.log(`       └─ ${chain.rpc}`);
        });
        console.log("");
        console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('Select chain (1-7): ', (answer: string) => {
            rl.close();
            
            const selection = parseInt(answer);
            const allChains = { ...chains.testnets, ...chains.mainnets };
            
            if (allChains[selection]) {
                resolve(allChains[selection]);
            } else {
                console.log("❌ Invalid selection");
                process.exit(1);
            }
        });
    });
};