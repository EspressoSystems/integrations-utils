# Transaction Load Generator (tx-load-gen)

A TypeScript-based tool that continuously sends transactions to EVM-compatible blockchains. Perfect for load testing, stress testing, and generating consistent transaction volume on various networks.

## Supported Networks

### Testnets

- Rari Testnet
- LogX Testnet  
- Appchain Testnet

### Mainnets

- Rari Mainnet
- LogX Mainnet
- Appchain Mainnet
- Molten Mainnet

## Prerequisites

- Node.js (v16 or higher)
- Yarn package manager
- A funded wallet private key for your target network

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/EspressoSystems/integrations-utils.git
   cd integrations-utils/tx-load-gen
   ```

2. **Install dependencies:**

   ```bash
   yarn install
   ```

3. **Set up environment variables:**

   From the root of the repo run:

   ```bash
   cp env.template .env
   ```

   Edit `.env` and add your private key:

   ```bash
   PRIVATE_KEY=your_private_key_here
   ```

## Configuration

You can customize the transaction generator behavior using environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PRIVATE_KEY` | Your wallet private key | **Required** |
| `DELAY_MS` | Delay between transactions (ms) | `10` |
| `TX_VALUE` | Transaction value in wei | `1` |
| `GAS_PRICE` | Gas price in gwei | `5` |

### Network RPC Override (Optional)

You can override default RPC URLs by setting these environment variables:

```bash
# Testnets
RARI_TESTNET_RPC=https://your-custom-rpc.com
LOGX_TESTNET_RPC=https://your-custom-rpc.com
APPCHAIN_TESTNET_RPC=https://your-custom-rpc.com

# Mainnets
RARI_MAINNET_RPC=https://your-custom-rpc.com
LOGX_MAINNET_RPC=https://your-custom-rpc.com
APPCHAIN_MAINNET_RPC=https://your-custom-rpc.com
MOLTEN_MAINNET_RPC=https://your-custom-rpc.com
```

## Usage

1. **Start the generator:**

   ```bash
   yarn start
   # or
   yarn dev
   ```

2. **Follow the interactive prompts:**
   - Select your target blockchain network (1-7)
   - Choose transaction data size (1-64 KB)

3. **Monitor the output:**
   - View configuration summary
   - Watch real-time transaction submissions
   - See transaction hashes and counts

4. **Stop the generator:**
   - Press `Ctrl+C` to gracefully stop

## Example Output

```
🔥 Transaction Load Generator

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 TESTNET NETWORKS

   1.  Rari Testnet
       └─ https://rari-testnet.calderachain.xyz/http
   2.  LogX Testnet
       └─ https://kartel-testnet.alt.technology
   3.  Appchain Testnet
       └─ https://appchaintestnet.rpc.caldera.xyz

🚀 MAINNET NETWORKS

   4.  Rari Mainnet
       └─ https://rari.calderachain.xyz/http
   5.  LogX Mainnet
       └─ https://vzjuxmhfn70kgnlds27h.alt.technology
   6.  Appchain Mainnet
       └─ https://appchain.calderachain.xyz/http
   7.  Molten Mainnet
       └─ https://molten.calderachain.xyz/http

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select chain (1-7): 3

✅ Selected: Appchain Testnet
Enter data size in KB (max 64): 23

✅ Data size: 23KB

📊 Configuration:
   Network:    Appchain Testnet
   RPC:        https://appchaintestnet.rpc.caldera.xyz
   Sender:     0x4df30AF0237E9a5c29D0f49a18Cb6f46692e3c71
   Delay:      10ms
   Value:      1 wei
   Gas Price:  5 gwei
   Data Size:  ~23KB
   Balance:    1.493155685479993854 ETH

🔍 Testing transaction estimation...
   Est. Gas:   401080

🎯 Starting continuous transaction generation...
Press Ctrl+C to stop

1. 0xd699088cedbde5b8885e3528a03eca5d73735c730e8c16fedd851b798c65476d
2. 0xe31520774ae35f861ca880099ca679b33c43795ff716d792ccd4f3189588fc26
3. 0xc6ea09dbba5f56adf2014ee30a44bd547a1cc3e12dd4913a5f814f0077dfcc13
```

## Script

- `yarn start` - Run the transaction generator

## Troubleshooting

### Common Issues

1. **"Insufficient funds"**
   - Check your wallet balance on the target network
   - Ensure you have enough ETH for gas fees

2. **RPC connection errors**
   - Verify the RPC endpoint is accessible
   - Try using a custom RPC URL in your `.env` file

3. **Transaction failures**
   - Check network congestion
   - Adjust gas price if needed
   - Verify recipient address is valid

## License

ISC
