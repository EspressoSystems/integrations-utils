import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const readline = require('readline');

export const selectDataSize = () => {
    return new Promise((resolve) => {
        console.log("\n📦 DATA SIZE OPTIONS");
        console.log("");
        console.log("   1.  Small    (1KB)");
        console.log("   2.  Medium   (10KB)");
        console.log("   3.  Large    (40KB)");
        console.log("   4.  Max      (64KB)");
        console.log("   5.  Custom   (specify KB)");
        console.log("");
        
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('Select data size (1-5): ', (answer) => {
            const selection = parseInt(answer);
            
            if (selection === 1) {
                rl.close();
                resolve(1);
            } else if (selection === 2) {
                rl.close();
                resolve(10);
            } else if (selection === 3) {
                rl.close();
                resolve(40);
            } else if (selection === 4) {
                rl.close();
                resolve(64);
            } else if (selection === 5) {
                rl.question('Enter KB size (max 64): ', (customSize) => {
                    rl.close();
                    const size = Math.min(parseInt(customSize) || 1, 64);
                    resolve(size);
                });
            } else {
                rl.close();
                console.log("❌ Invalid selection");
                process.exit(1);
            }
        });
    });
};

export const selectChain = (chains) => {
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
        
        rl.question('Select chain (1-7): ', (answer) => {
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