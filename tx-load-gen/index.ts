import { ethers } from "ethers";
import { webcrypto } from 'node:crypto';
import { selectDataSize, selectChain } from './selectors.ts';
import { CHAINS } from './chains.ts';
import type { Config, TransactionDetails } from './types.ts';

const getPrivateKey = (): string => {
    const envKey = process.env.PRIVATE_KEY;
    if (envKey) {
        return envKey;
    }
    
    console.log("\n🔑 No valid PRIVATE_KEY found in environment");
    console.log("💡 Please set PRIVATE_KEY in .env file");
    process.exit(1);
};

const generateRandomData = (sizeKB: number): string => {
    if (sizeKB <= 0) return '0x';
    const sizeBytes = Math.min(sizeKB * 1024, 65536); // cap at webcrypto limit
    const array = new Uint8Array(sizeBytes);
    webcrypto.getRandomValues(array);
    return '0x' + Buffer.from(array).toString('hex');
};

const getConfig = (): Config => {
    return {
        delayMs: parseInt(process.env.DELAY_MS || '') || 10,
        value: process.env.TX_VALUE || '1', // wei
        gasPrice: process.env.GAS_PRICE || '5', // gwei
        to: process.env.TO_ADDRESS
    };
};

const main = async (): Promise<void> => {
    console.log("🔥 Transaction Load Generator");
    
    const selectedChain = await selectChain(CHAINS);
    console.log(`\n✅ Selected: ${selectedChain.name}`);
    
    const selectedDataSize = await selectDataSize();
    console.log(`\n✅ Data size: ${selectedDataSize}KB`);
    
    const config = getConfig();
    const privateKey = getPrivateKey();
    
    const provider = new ethers.JsonRpcProvider(selectedChain.rpc);
    const signer = new ethers.Wallet(privateKey, provider);
    
    const txData = generateRandomData(selectedDataSize);
    const txDetails: TransactionDetails = {
        from: signer.address,
        to: config.to || signer.address,
        value: ethers.parseUnits(config.value, 'wei'),
        gasPrice: ethers.parseUnits(config.gasPrice, 'gwei'),
        data: txData
    };
    
    console.log(`\n📊 Configuration:`);
    console.log(`   Network:    ${selectedChain.name}`);
    console.log(`   RPC:        ${selectedChain.rpc}`);
    console.log(`   Sender:     ${signer.address}`);
    console.log(`   Recipient:  ${txDetails.to}`);
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
                
                await new Promise<void>(resolve => setTimeout(resolve, config.delayMs));
            } catch (error: any) {
                console.error(`❌ TX Error: ${error.shortMessage || error.message}`);

                await new Promise<void>(resolve => setTimeout(resolve, config.delayMs));
            }
        }
        
    } catch (error: any) {
        console.error(`❌ Setup Error: ${error.shortMessage || error.message}`);
        process.exit(1);
    }
};

main().catch((error: any) => {
    console.error(`❌ Fatal Error: ${error.message}`);
    process.exit(1);
});