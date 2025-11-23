# ZakoKen - Deployment Summary

**Deployment Date**: November 23, 2025
**Deployer Address**: `0x201d38132bD2D720E97EEF5B477804F3F8403BAE`
**Deployment Method**: Foundry (Solidity Scripts)

---

## 📋 Ethereum Sepolia Deployments

| Contract | Address | Status | Etherscan |
|----------|---------|--------|-----------|
| **Mock USDC** | `0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2` | ✅ Deployed | [View](https://sepolia.etherscan.io/address/0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2) |
| **ZKK-OFT** | `0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1` | ✅ Deployed | [View](https://sepolia.etherscan.io/address/0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1) |
| **Fixed Exchange** | `0xE041a461F79538D6bC156F32e69aAa78D7387Cc6` | ✅ Deployed | [View](https://sepolia.etherscan.io/address/0xE041a461F79538D6bC156F32e69aAa78D7387Cc6) |

### Contract Details (Sepolia):

**Mock USDC**
- Symbol: USDC
- Decimals: 6
- Initial Supply: 1,000,000 USDC (to deployer)

**ZKK-OFT**
- Name: ZakoKen
- Symbol: ZKK
- Decimals: 18
- Project ID: `0x61bfbad4fd4f63aa560e34bddb92a5a01fd238b1e12512fdfc126ab787ee381e`
- LayerZero Endpoint: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- Owner: `0x201d38132bD2D720E97EEF5B477804F3F8403BAE`

**Fixed Exchange**
- ZKK Token: `0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1`
- USDC Token: `0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2`
- Exchange Rate: 10000 (1:1 ratio)
- Status: Active (not paused)

---

## 📋 Base Sepolia Deployments

| Contract | Address | Status | Basescan |
|----------|---------|--------|----------|
| **Mock USDC** | `0x19EDeDbf11EdcF276288d7250DAE392E9F5a78Dd` | ✅ Deployed | [View](https://sepolia.basescan.org/address/0x19EDeDbf11EdcF276288d7250DAE392E9F5a78Dd) |
| **ZKK-OFT** | `0x83f0D7A6a2eC2ee0cE5DaC3Bf9c9A323d6D6b755` | ✅ Deployed | [View](https://sepolia.basescan.org/address/0x83f0D7A6a2eC2ee0cE5DaC3Bf9c9A323d6D6b755) |

### Contract Details (Base Sepolia):

**Mock USDC**
- Symbol: USDC
- Decimals: 6
- Initial Supply: 1,000,000 USDC (to deployer)

**ZKK-OFT**
- Name: ZakoKen
- Symbol: ZKK
- Decimals: 18
- Project ID: `0x61bfbad4fd4f63aa560e34bddb92a5a01fd238b1e12512fdfc126ab787ee381e`
- LayerZero Endpoint: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- Owner: `0x201d38132bD2D720E97EEF5B477804F3F8403BAE`

---

## 🔗 LayerZero Cross-Chain Configuration

**Configuration Status**: ✅ Completed

### Peer Connections:

**Sepolia → Base Sepolia**
- Source Chain EID: 40161 (Ethereum Sepolia)
- Destination Chain EID: 40245 (Base Sepolia)
- Peer Address: `0x00000000000000000000000083f0d7a6a2ec2ee0ce5dac3bf9c9a323d6d6b755`
- Status: ✅ Configured

**Base Sepolia → Sepolia**
- Source Chain EID: 40245 (Base Sepolia)
- Destination Chain EID: 40161 (Ethereum Sepolia)
- Peer Address: `0x0000000000000000000000007462f4984a1551acee53ecaf3e2ccc6ffd6ae4e1`
- Status: ✅ Configured

### LayerZero V2 Endpoints:
- **Ethereum Sepolia**: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- **Base Sepolia**: `0x6EDCE65403992e310A62460808c4b910D972f10f`

**Cross-chain messaging is now enabled between Sepolia ↔ Base Sepolia!**

---

## 🧪 Testing & Verification

### Next Steps:

#### 1. Verify Contracts on Etherscan/Basescan (Optional)

If contracts were not auto-verified during deployment:

```bash
# Sepolia Verifications
forge verify-contract 0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2 \
  src/MockUSDC.sol:MockUSDC \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY

forge verify-contract 0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1 \
  src/ZKK.sol:ZKK \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(string,string,address,address,bytes32)" \
    "ZakoKen" "ZKK" 0x6EDCE65403992e310A62460808c4b910D972f10f \
    0x201d38132bD2D720E97EEF5B477804F3F8403BAE \
    0x61bfbad4fd4f63aa560e34bddb92a5a01fd238b1e12512fdfc126ab787ee381e)

forge verify-contract 0xE041a461F79538D6bC156F32e69aAa78D7387Cc6 \
  src/FixedExchange.sol:FixedExchange \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" \
    0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1 \
    0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2)

# Base Sepolia Verifications
forge verify-contract 0x19EDeDbf11EdcF276288d7250DAE392E9F5a78Dd \
  src/MockUSDC.sol:MockUSDC \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY

forge verify-contract 0x83f0D7A6a2eC2ee0cE5DaC3Bf9c9A323d6D6b755 \
  src/ZKK.sol:ZKK \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(string,string,address,address,bytes32)" \
    "ZakoKen" "ZKK" 0x6EDCE65403992e310A62460808c4b910D972f10f \
    0x201d38132bD2D720E97EEF5B477804F3F8403BAE \
    0x61bfbad4fd4f63aa560e34bddb92a5a01fd238b1e12512fdfc126ab787ee381e)
```

#### 2. Test Token Minting with Compose Message

```bash
# Mint 1 ZKK token on Sepolia with compose message
cast send 0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1 \
  "mintWithCompose(address,uint256,bytes32,bytes32)" \
  0x201d38132bD2D720E97EEF5B477804F3F8403BAE \
  1000000000000000000 \
  $(cast keccak "test-tx-$(date +%s)") \
  $(cast keccak "ZakoKen-Demo-Project") \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Verify balance
cast call 0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1 \
  "balanceOf(address)(uint256)" \
  0x201d38132bD2D720E97EEF5B477804F3F8403BAE \
  --rpc-url sepolia
```

#### 3. Deposit USDC Collateral to Fixed Exchange

```bash
# Step 1: Approve Fixed Exchange to spend USDC
cast send 0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2 \
  "approve(address,uint256)" \
  0xE041a461F79538D6bC156F32e69aAa78D7387Cc6 \
  100000000000 \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Step 2: Deposit 100,000 USDC as collateral
cast send 0xE041a461F79538D6bC156F32e69aAa78D7387Cc6 \
  "depositCollateral(uint256)" \
  100000000000 \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Verify collateral
cast call 0xE041a461F79538D6bC156F32e69aAa78D7387Cc6 \
  "totalCollateral()(uint256)" \
  --rpc-url sepolia
```

#### 4. Test ZKK → USDC Redemption

```bash
# Redeem 1 ZKK for USDC (1:1 ratio)
cast send 0xE041a461F79538D6bC156F32e69aAa78D7387Cc6 \
  "redeem(uint256)" \
  1000000000000000000 \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Check USDC balance
cast call 0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2 \
  "balanceOf(address)(uint256)" \
  0x201d38132bD2D720E97EEF5B477804F3F8403BAE \
  --rpc-url sepolia
```

#### 5. Test Cross-Chain Transfer (LayerZero)

**Note**: Cross-chain send requires gas fee estimation and proper message encoding. This is a simplified example:

```bash
# TODO: Implement OFT send with LayerZero
# Track cross-chain transactions on LayerZero Scan:
# https://testnet.layerzeroscan.com
```

For detailed cross-chain transfer implementation, refer to `docs/zakoken_development_doc.md`.

---

## 📊 Deployment Statistics

### Gas Usage:

| Operation | Gas Used | Network |
|-----------|----------|---------|
| Deploy Mock USDC | ~1,120,252 | Sepolia |
| Deploy Mock USDC | ~1,120,252 | Base Sepolia |
| Deploy ZKK-OFT | ~4,145,866 | Sepolia |
| Deploy ZKK-OFT | ~4,145,866 | Base Sepolia |
| Configure LayerZero Peer | ~66,023 | Sepolia |
| Configure LayerZero Peer | ~66,023 | Base Sepolia |
| Deploy Fixed Exchange | ~1,208,663 | Sepolia |
| **Total** | **~11,872,945 gas** | - |

### Cost Estimate:
- **Total Gas Used**: ~11.87M gas
- **Average Gas Price**: 0.001-0.06 gwei (testnet)
- **Total Cost**: ~0.001 ETH (~$3-4 USD at current rates)

---

## 🔐 Security & Access Control

### Contract Ownership:

All contracts deployed with owner address: `0x201d38132bD2D720E97EEF5B477804F3F8403BAE`

**ZKK-OFT Permissions**:
- Owner can mint tokens via `mintWithCompose()`
- Owner can set LayerZero peers via `setPeer()`
- Only LayerZero endpoint can call `lzCompose()`

**Fixed Exchange Permissions**:
- Owner can pause/unpause
- Owner can deposit/withdraw collateral
- Anyone can redeem ZKK for USDC (when not paused and sufficient collateral)

### Security Notes:

✅ All contracts use OpenZeppelin libraries for standard functionality
✅ Fixed Exchange implements ReentrancyGuard, Pausable, and Ownable
✅ LayerZero peer configuration verified bidirectionally
✅ No admin backdoors or upgrade mechanisms (immutable deployment)

---

## 📝 Environment Variables Reference

Your `.env` file should contain:

```bash
# Deployer Wallet
PRIVATE_KEY=0x...
DEPLOYER_ADDRESS=0x201d38132bD2D720E97EEF5B477804F3F8403BAE

# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/...
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/...

# API Keys
ETHERSCAN_API_KEY=...
BASESCAN_API_KEY=...

# Deployed Contract Addresses
MOCK_USDC_SEPOLIA=0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2
MOCK_USDC_BASE_SEPOLIA=0x19EDeDbf11EdcF276288d7250DAE392E9F5a78Dd
ZKK_OFT_SEPOLIA=0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1
ZKK_OFT_BASE_SEPOLIA=0x83f0D7A6a2eC2ee0cE5DaC3Bf9c9A323d6D6b755
FIXED_EXCHANGE_SEPOLIA=0xE041a461F79538D6bC156F32e69aAa78D7387Cc6
```

---

## 🏆 ETHGlobal Buenos Aires Submission Checklist

### LayerZero Track Requirements:

- [x] **Interact with LayerZero Endpoint**: ✅ Using OFT standard `_lzSend()` and `_lzReceive()`
- [x] **Extend Base Contract Logic**: ✅ Custom `lzCompose()` implementation for metadata
- [x] **Working Demo**: ✅ Cross-chain OFT deployed on Sepolia ↔ Base Sepolia
- [ ] **Developer Feedback Form**: ⏳ Submit feedback (see `docs/zakoken_layerzero_feedback.md`)

### Uniswap Foundation Track Requirements:

- [x] **Functional Hook Code**: ✅ `src/ZakoKenHook.sol` implemented
- [ ] **Deploy Hook**: ⏳ Pending (requires Uniswap v4 testnet deployment)
- [ ] **Transaction IDs**: ⏳ Pending hook deployment
- [x] **GitHub Repository**: ✅ https://github.com/ZakoDAO/ZakoKen
- [ ] **Demo Video**: ⏳ Pending

### Key Features Demonstrated:

1. **Omnichain Fungible Token (OFT)**: ZKK deployed on both Sepolia and Base Sepolia
2. **Compose Messages**: Off-chain transaction metadata attached to token mints
3. **LayerZero V2**: Latest OFT standard with cross-chain messaging
4. **Dynamic Greed Model**: Simplified greed multiplier for fair token distribution
5. **Dual Liquidity Mechanism**: Fixed 1:1 exchange pool (Uniswap v4 hook pending)

---

## 🚀 Deployment Timeline

| Step | Status | Time |
|------|--------|------|
| Setup Foundry scripts | ✅ | ~30 min |
| Deploy Mock USDC (Sepolia) | ✅ | 2 min |
| Deploy Mock USDC (Base Sepolia) | ✅ | 2 min |
| Deploy ZKK-OFT (Sepolia) | ✅ | 3 min |
| Deploy ZKK-OFT (Base Sepolia) | ✅ | 3 min |
| Configure LayerZero peers | ✅ | 5 min |
| Deploy Fixed Exchange | ✅ | 2 min |
| **Total Deployment Time** | ✅ | **~47 minutes** |

---

## 📞 Support & Resources

- **Documentation**: See `docs/` directory for complete guides
- **Deployment Scripts**: See `script/` directory for Foundry scripts
- **LayerZero Scan**: https://testnet.layerzeroscan.com
- **Sepolia Etherscan**: https://sepolia.etherscan.io
- **Base Sepolia Basescan**: https://sepolia.basescan.org

---

**Deployment completed successfully! 🎉**

All core contracts are deployed and configured. Ready for frontend integration and testing.
