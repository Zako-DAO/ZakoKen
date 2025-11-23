# Deployment Scripts

This directory contains all deployment and utility scripts for the ZakoKen protocol.

## Quick Start

### 1. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env and fill in:
# - PRIVATE_KEY (your wallet private key)
# - SEPOLIA_RPC_URL (Alchemy/Infura)
# - BASE_SEPOLIA_RPC_URL
# - ETHERSCAN_API_KEY
# - BASESCAN_API_KEY
```

### 2. Deploy All Contracts (Single Chain)

```bash
# Deploy on Sepolia
pnpm hardhat run scripts/deploy-all.ts --network sepolia

# Or deploy on Base Sepolia
pnpm hardhat run scripts/deploy-all.ts --network baseSepolia
```

This will deploy:
1. MockUSDC
2. ZKK OFT Token
3. FixedExchange

### 3. Setup Demo Environment

```bash
# Mint test tokens and setup collateral
pnpm hardhat run scripts/setup-demo.ts --network sepolia
```

This will:
- Mint 100k USDC
- Deposit 50k USDC as collateral
- Mint 1000 ZKK tokens

## Individual Deployment Scripts

### Deploy MockUSDC

```bash
pnpm hardhat run scripts/deploy-usdc.ts --network sepolia
```

Deploys a mock USDC token with 6 decimals for testing.

### Deploy ZKK OFT

```bash
pnpm hardhat run scripts/deploy-zkk.ts --network sepolia
```

Deploys the ZakoKen OFT token with LayerZero integration.

### Deploy FixedExchange

```bash
pnpm hardhat run scripts/deploy-exchange.ts --network sepolia
```

Deploys the 1:1 USDC redemption pool. Requires USDC and ZKK to be deployed first.

## Cross-Chain Setup

### 1. Deploy on Both Chains

```bash
# Deploy on Sepolia
pnpm hardhat run scripts/deploy-all.ts --network sepolia

# Deploy on Base Sepolia
pnpm hardhat run scripts/deploy-all.ts --network baseSepolia
```

### 2. Configure LayerZero Peers

```bash
# This script will set up trusted peers on both chains
pnpm hardhat run scripts/configure-layerzero.ts
```

**Note:** This script connects to both Sepolia and Base Sepolia automatically. Make sure both `SEPOLIA_RPC_URL` and `BASE_SEPOLIA_RPC_URL` are set in your `.env`.

## Verification

After deployment, verify contracts on Etherscan:

```bash
# Verify MockUSDC
pnpm hardhat verify --network sepolia <USDC_ADDRESS>

# Verify ZKK OFT
pnpm hardhat verify --network sepolia <ZKK_ADDRESS> \
  "ZakoKen" "ZKK" "<LZ_ENDPOINT>" "<OWNER_ADDRESS>" "<PROJECT_ID>"

# Verify FixedExchange
pnpm hardhat verify --network sepolia <EXCHANGE_ADDRESS> \
  "<ZKK_ADDRESS>" "<USDC_ADDRESS>" "<OWNER_ADDRESS>"
```

The deployment scripts will output the exact verification commands.

## Deployment Files

All deployments are saved in the `deployments/` directory:

```
deployments/
├── usdc-sepolia.json
├── zkk-sepolia.json
├── exchange-sepolia.json
├── usdc-baseSepolia.json
├── zkk-baseSepolia.json
└── exchange-baseSepolia.json
```

Each file contains:
- Contract addresses
- Constructor arguments
- Deployment timestamp
- Network information

## Utility Functions

Helper functions are available in `scripts/utils/helpers.ts`:

```typescript
import { loadDeployment, saveDeployment, waitForTx } from "./utils/helpers.js";

// Load a deployment
const deployment = loadDeployment("zkk", "sepolia");
const zkkAddress = deployment.contracts.ZKK.address;

// Save a deployment
saveDeployment("MyContract", "sepolia", 11155111, deployer, {
  address: contractAddress,
  // ... other data
});

// Wait for transaction with nice logging
await waitForTx(tx, "Minting tokens");
```

## Network Configuration

Networks are configured in `hardhat.config.ts`:

- **sepolia**: Ethereum Sepolia testnet
- **baseSepolia**: Base Sepolia testnet
- **hardhat**: Local Hardhat network

LayerZero Endpoint IDs (EIDs):
- Sepolia: `40161`
- Base Sepolia: `40245`

## Troubleshooting

### "Deployment file not found"

Make sure you've deployed the prerequisite contracts:
1. USDC must be deployed before FixedExchange
2. ZKK must be deployed before FixedExchange

### "Insufficient funds"

Get testnet ETH from faucets:
- Sepolia: https://sepoliafaucet.com
- Base Sepolia: https://faucet.quicknode.com/base/sepolia

### LayerZero peer configuration fails

1. Check that contracts are deployed on both chains
2. Verify RPC URLs are correct in `.env`
3. Ensure you have enough ETH on both networks

### Compilation errors

```bash
# Clean and recompile
pnpm hardhat clean
pnpm hardhat compile
```

## Script Workflow

Recommended deployment order:

1. **Single Chain Setup:**
   ```bash
   pnpm hardhat run scripts/deploy-all.ts --network sepolia
   pnpm hardhat run scripts/setup-demo.ts --network sepolia
   ```

2. **Cross-Chain Setup:**
   ```bash
   # Deploy on both chains
   pnpm hardhat run scripts/deploy-all.ts --network sepolia
   pnpm hardhat run scripts/deploy-all.ts --network baseSepolia

   # Configure LayerZero
   pnpm hardhat run scripts/configure-layerzero.ts

   # Setup demo on primary chain
   pnpm hardhat run scripts/setup-demo.ts --network sepolia
   ```

3. **Verify Contracts:**
   - Use verification commands from deployment output
   - Check contracts on Etherscan

4. **Test Cross-Chain:**
   - Use frontend or write custom test scripts
   - Monitor on LayerZero Scan: https://testnet.layerzeroscan.com

## Additional Resources

- [Hardhat Documentation](https://hardhat.org/docs)
- [LayerZero V2 Docs](https://docs.layerzero.network/v2)
- [Etherscan API](https://docs.etherscan.io/)
