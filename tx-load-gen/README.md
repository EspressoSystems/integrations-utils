# Transaction Load Generator (tx-load-gen)

A TypeScript-based tool that continuously sends transactions to EVM-compatible blockchains. Perfect for load testing, stress testing, and generating consistent transaction volume on various testnet networks.

## Supported Networks

### Testnets

- **Rari Testnet**
- **LogX Testnet**
- **Appchain Testnet**
- **NodeOps Testnet**
- **Apechain Testnet**
- **Rufus Testnet**
- **T3rn Testnet**
- **Huddle01**
- **Custom Network**

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
| `TO_ADDRESS` | Recipient address for transactions | Sender's own address |
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
NODEOPS_TESTNET_RPC=https://your-custom-rpc.com
APECHAIN_TESTNET_RPC=https://your-custom-rpc.com
RUFUS_TESTNET_RPC=https://your-custom-rpc.com
T3RN_TESTNET_RPC=https://your-custom-rpc.com
HUDDLE01_RPC=https://your-custom-rpc.com

# Custom Network
CUSTOM_RPC=https://your-custom-rpc-endpoint.com
```

### Custom Network Setup

To use a custom network:

1. Set the `CUSTOM_RPC` environment variable to your RPC endpoint URL
2. Select option `9` (Custom Network) when prompted
3. Ensure your wallet has funds on the custom network

Example:
```bash
CUSTOM_RPC=https://my-private-testnet.com/rpc
```

## Usage

1. **Start the generator:**

   ```bash
   yarn start
   # or
   yarn dev
   ```

2. **Follow the interactive prompts:**
   - Select your target blockchain network (1-9)
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
   4.  NodeOps Testnet
       └─ https://nodeops-orchestrator-network.calderachain.xyz/http
   5.  Apechain Testnet
       └─ https://apechain-testnet.rpc.caldera.xyz/http
   6.  Rufus Testnet
       └─ https://rufus-sepolia-testnet.rpc.caldera.xyz/http
   7.  T3rn Testnet
       └─ https://brn-testnet.rpc.caldera.xyz/http
   8.  Huddle01
       └─ https://huddle-testnet.rpc.caldera.xyz/http
   9.  Custom Network
       └─ https://your-custom-rpc-endpoint.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select chain (1-9): 6

✅ Selected: Rufus Testnet
Enter data size in KB (max 64): 4

✅ Data size: 4KB

📊 Configuration:
   Network:    Rufus Testnet
   RPC:        https://rufus-sepolia-testnet.rpc.caldera.xyz/http
   Sender:     0x4df30AF0237E9a5c29D0f49a18Cb6f46692e3c71
   Delay:      10ms
   Value:      1 wei
   Gas Price:  5 gwei
   Data Size:  ~4KB
   Balance:    1.493155685479993854 ETH

🔍 Testing transaction estimation...
   Est. Gas:   82160

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
   - Check your wallet balance on the target testnet
   - Ensure you have enough testnet ETH for gas fees
   - For custom networks, fund your wallet appropriately

2. **RPC connection errors**
   - Verify the RPC endpoint is accessible and responding
   - Try using a custom RPC URL override in your `.env` file
   - For custom networks, ensure the RPC endpoint supports standard Ethereum JSON-RPC methods

3. **Transaction failures**
   - Check network congestion and status
   - Adjust gas price if needed (`GAS_PRICE` env var)
   - Verify recipient address is valid (or use default self-address)
   - Ensure the network supports the transaction parameters you're using

4. **Custom network issues**
   - Verify `CUSTOM_RPC` URL is correct and accessible
   - Confirm the custom network is EVM-compatible
   - Check that your wallet has the correct format for that network

## License

ISC
