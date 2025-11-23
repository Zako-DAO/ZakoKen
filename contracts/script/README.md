# Foundry Deployment Scripts

## 🚀 Quick Start

### Prerequisites

1. **Environment Variables**: Ensure `.env` is configured with:
   ```bash
   PRIVATE_KEY=your_private_key_without_0x
   SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
   BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY
   ETHERSCAN_API_KEY=your_etherscan_key
   BASESCAN_API_KEY=your_basescan_key
   ```

2. **Testnet ETH**: Ensure your wallet has sufficient ETH on both networks

### Step-by-Step Deployment

#### 1. Deploy Mock USDC on Sepolia

```bash
forge script script/DeployMockUSDC.s.sol:DeployMockUSDC \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv
```

Copy the deployed address and add to `.env`:
```bash
MOCK_USDC_SEPOLIA=0x...
```

#### 2. Deploy Mock USDC on Base Sepolia

```bash
forge script script/DeployMockUSDC.s.sol:DeployMockUSDC \
  --rpc-url baseSepolia \
  --broadcast \
  --verify \
  -vvvv
```

Add to `.env`:
```bash
MOCK_USDC_BASE_SEPOLIA=0x...
```

#### 3. Deploy ZKK OFT on Sepolia

```bash
forge script script/DeployZKK.s.sol:DeployZKK \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv
```

Add to `.env`:
```bash
ZKK_OFT_SEPOLIA=0x...
```

#### 4. Deploy ZKK OFT on Base Sepolia

```bash
forge script script/DeployZKK.s.sol:DeployZKK \
  --rpc-url baseSepolia \
  --broadcast \
  --verify \
  -vvvv
```

Add to `.env`:
```bash
ZKK_OFT_BASE_SEPOLIA=0x...
```

#### 5. Configure LayerZero Peers

**On Sepolia:**
```bash
forge script script/ConfigureLayerZero.s.sol:ConfigureLayerZero \
  --rpc-url sepolia \
  --broadcast \
  -vvvv
```

**On Base Sepolia:**
```bash
forge script script/ConfigureLayerZero.s.sol:ConfigureLayerZero \
  --rpc-url baseSepolia \
  --broadcast \
  -vvvv
```

#### 6. Deploy Fixed Exchange on Sepolia

```bash
forge script script/DeployFixedExchange.s.sol:DeployFixedExchange \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv
```

Add to `.env`:
```bash
FIXED_EXCHANGE_SEPOLIA=0x...
```

## 📝 One-Command Deployment

For quick deployment, you can chain commands:

```bash
# Deploy everything on Sepolia
forge script script/DeployMockUSDC.s.sol --rpc-url sepolia --broadcast --verify && \
forge script script/DeployZKK.s.sol --rpc-url sepolia --broadcast --verify && \
forge script script/DeployFixedExchange.s.sol --rpc-url sepolia --broadcast --verify

# Deploy everything on Base Sepolia
forge script script/DeployMockUSDC.s.sol --rpc-url baseSepolia --broadcast --verify && \
forge script script/DeployZKK.s.sol --rpc-url baseSepolia --broadcast --verify

# Configure LayerZero peers
forge script script/ConfigureLayerZero.s.sol --rpc-url sepolia --broadcast && \
forge script script/ConfigureLayerZero.s.sol --rpc-url baseSepolia --broadcast
```

## 🔍 Verification

If verification fails during deployment, you can verify manually:

```bash
# MockUSDC
forge verify-contract <ADDRESS> src/MockUSDC.sol:MockUSDC \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY

# ZKK
forge verify-contract <ADDRESS> src/ZKK.sol:ZKK \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(string,string,address,address,bytes32)" "ZakoKen" "ZKK" <LZ_ENDPOINT> <OWNER> <PROJECT_ID>)

# FixedExchange
forge verify-contract <ADDRESS> src/FixedExchange.sol:FixedExchange \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" <ZKK> <USDC> <OWNER>)
```

## 🧪 Testing Cross-Chain Transfer

After deployment and configuration, test the cross-chain transfer:

```bash
# Mint some ZKK on Sepolia
cast send $ZKK_OFT_SEPOLIA "mintWithCompose(address,uint256,bytes32,bytes32)" \
  <RECIPIENT> \
  1000000000000000000 \
  $(cast keccak "test-tx") \
  $(cast keccak "ZakoKen-Demo-Project") \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Check balance
cast call $ZKK_OFT_SEPOLIA "balanceOf(address)(uint256)" <RECIPIENT> --rpc-url sepolia
```

## 📊 Useful Commands

```bash
# Check deployment info
forge script script/DeployZKK.s.sol --rpc-url sepolia

# Estimate gas
forge script script/DeployZKK.s.sol --rpc-url sepolia --estimate-gas

# Dry run (no broadcast)
forge script script/DeployZKK.s.sol --rpc-url sepolia -vvvv

# Debug
forge script script/DeployZKK.s.sol --rpc-url sepolia --debug
```

## ⚠️ Troubleshooting

### "Insufficient balance" Error
- Check wallet balance: `cast balance <ADDRESS> --rpc-url sepolia`
- Get testnet ETH from faucets

### "Contract already deployed" Error
- Check existing deployments in `broadcast/` directory
- Use `--resume` flag to resume failed deployment

### "Verification failed" Error
- Wait a few seconds and try manual verification
- Check constructor arguments match exactly

### "Invalid RPC URL" Error
- Verify .env file is loaded: `source .env`
- Check RPC URL format and API key

## 📂 Deployment Records

All deployment transactions are saved in:
```
broadcast/<ScriptName>.s.sol/<ChainID>/
```

You can review past deployments by checking these JSON files.
