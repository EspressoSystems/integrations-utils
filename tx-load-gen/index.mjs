import { ethers } from "ethers";
import { createRequire } from 'module';
import fs from 'fs';
import { webcrypto } from 'node:crypto';

const require = createRequire(import.meta.url);
const readline = require('readline');

if (fs.existsSync('../.env')) {
    fs.readFileSync('../.env', 'utf8')
        .split('\n')
        .forEach(line => {
            const [key, value] = line.split('=');
            if (key && value) process.env[key] = value;
        });
    console.log('✅ Loaded .env');
}

const CHAINS = {
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

const getPrivateKey = () => {
    const envKey = process.env.PRIVATE_KEY;
    if (envKey) {
        return envKey;
    }
    
    console.log("\n🔑 No valid PRIVATE_KEY found in environment");
    console.log("💡 Please set PRIVATE_KEY in .env file");
    process.exit(1);
};

const selectDataSize = () => {
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

const selectChain = () => {
    return new Promise((resolve) => {
        console.log("\n");
        console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        console.log("");
        console.log("🌐 TESTNET NETWORKS");
        console.log("");
        Object.entries(CHAINS.testnets).forEach(([key, chain]) => {
            console.log(`   ${key}.  ${chain.name}`);
            console.log(`       └─ ${chain.rpc}`);
        });
        console.log("");
        console.log("🚀 MAINNET NETWORKS");
        console.log("");
        Object.entries(CHAINS.mainnets).forEach(([key, chain]) => {
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
            const allChains = { ...CHAINS.testnets, ...CHAINS.mainnets };
            
            if (allChains[selection]) {
                resolve(allChains[selection]);
            } else {
                console.log("❌ Invalid selection");
                process.exit(1);
            }
        });
    });
};

const generateRandomData = (sizeKB) => {
    if (sizeKB <= 0) return '0x';
    const sizeBytes = Math.min(sizeKB * 1024, 65536); // cap at webcrypto limit
    const array = new Uint8Array(sizeBytes);
    webcrypto.getRandomValues(array);
    return '0x' + Buffer.from(array).toString('hex');
};

const getConfig = () => {
    return {
        delayMs: parseInt(process.env.DELAY_MS) || 10,
        value: process.env.TX_VALUE || '1', // wei
        gasPrice: process.env.GAS_PRICE || '5' // gwei
    };
};

const main = async () => {
    console.log("🔥 Transaction Load Generator");
    
    const selectedChain = await selectChain();
    console.log(`\n✅ Selected: ${selectedChain.name}`);
    
    const selectedDataSize = await selectDataSize();
    console.log(`\n✅ Data size: ${selectedDataSize}KB`);
    
    const config = getConfig();
    const privateKey = getPrivateKey();
    
    const provider = new ethers.JsonRpcProvider(selectedChain.rpc);
    const signer = new ethers.Wallet(privateKey, provider);
    
    const txData = generateRandomData(selectedDataSize);
    const txDetails = {
        from: signer.address,
        to: config.to || '0x00000000000000000000000000000000ffffffff',
        value: ethers.parseUnits(config.value, 'wei'),
        gasPrice: ethers.parseUnits(config.gasPrice, 'gwei'),
        data: txData
    };
    
    console.log(`\n📊 Configuration:`);
    console.log(`   Network:    ${selectedChain.name}`);
    console.log(`   RPC:        ${selectedChain.rpc}`);
    console.log(`   Sender:     ${signer.address}`);
    console.log(`   Delay:      ${config.delayMs}ms`);
    console.log(`   Value:      ${config.value} wei`);
    console.log(`   Gas Price:  ${config.gasPrice} gwei`);
    console.log(`   Data Size:  ~${selectedDataSize}KB`);
    
    try {
        const balance = await provider.getBalance(signer.address);
        console.log(`   Balance:    ${ethers.formatEther(balance)} ETH`);

        console.log(`\n🔍 Testing transaction estimation...`);
        const estimatedGas = await provider.estimateGas(txDetails);
        console.log(`   Est. Gas:   ${estimatedGas.toString()}`);
        
        console.log(`\n🎯 Starting continuous transaction generation...`);
        console.log('Press Ctrl+C to stop\n');
        
        let txCount = 0;
        while (true) {
            try {
                const tx = await signer.sendTransaction({
                    ...txDetails,
                    gasLimit: estimatedGas,
                });
                txCount++;
                console.log(`${txCount}. ${tx.hash}`);
                
                await new Promise(resolve => setTimeout(resolve, config.delayMs));
            } catch (error) {
                console.error(`❌ TX Error: ${error.shortMessage || error.message}`);

                await new Promise(resolve => setTimeout(resolve, config.delayMs));
            }
        }
        
    } catch (error) {
        console.error(`❌ Setup Error: ${error.shortMessage || error.message}`);
        process.exit(1);
    }
};

main().catch(error => {
    console.error(`❌ Fatal Error: ${error.message}`);
    process.exit(1);
});