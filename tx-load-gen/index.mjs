import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider('https://appchaintestnet.rpc.caldera.xyz'); // Appchain testnet RPC URL
const signer = new ethers.Wallet('PRIVATE_KEY', provider);

const txDetails = {
    from: signer.address,
    to: 'DESTINATION_ADDRESS',
    value: ethers.parseUnits('1', 'wei'),
    gasPrice: ethers.parseUnits('10', 'gwei'),
};

let staticEstimatedGas;

const initialize = async () => {
    try {ß
        const balance = await provider.getBalance(signer.address);
        console.log(`Sender: ${signer.address}, Balance: ${ethers.formatEther(balance)} ETH`);
        staticEstimatedGas = await provider.estimateGas(txDetails);
        console.log("Starting transaction loop...");
        return true;
    } catch (error) {
        console.error("Initialization Error:", error.shortMessage || error.message);
        return false;
    }
};


const executeTransaction = async () => {
    if (!staticEstimatedGas) {
        console.error("Critical: staticEstimatedGas not available."); 
        return;
    }
    try {
        const tx = await signer.sendTransaction({
            ...txDetails,
            gasLimit: staticEstimatedGas,
        });
        console.log(tx.hash);
    } catch (error) {
        console.error("Tx Error:", error.shortMessage || error.message);
    }
};

const mainLoop = async () => {
    const initialized = await initialize();
    if (!initialized) {
        process.exit(1);
    }

    while (true) {
        await executeTransaction();
    }
};

mainLoop().catch(error => {
    process.exit(1);
}); 