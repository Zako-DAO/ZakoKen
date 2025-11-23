# ZakoKen - ETHGlobal Buenos Aires Hackathon Guide

**⏰ TIMELINE: 18 hours remaining (3:00 PM → 9:00 AM submission deadline)**

---

## 📋 Table of Contents

1. [Quick Start](#quick-start) - **START HERE**
2. [18-Hour Execution Plan](#18-hour-execution-plan)
3. [Project Overview](#project-overview)
4. [Technical Architecture](#technical-architecture)
5. [Smart Contract Specifications](#smart-contract-specifications)
6. [Frontend Design](#frontend-design)
7. [Demo Video Script](#demo-video-script)
8. [Submission Checklist](#submission-checklist)
9. [Resources](#resources)
10. [Troubleshooting](#troubleshooting)

---

## Quick Start

**⚡ DO THIS FIRST (15 minutes)**

### 1. Setup Environment (5 minutes)
```bash
# Copy environment template
cp .env.example .env

# Edit .env - add your:
# - PRIVATE_KEY (without 0x)
# - SEPOLIA_RPC_URL (from Alchemy/Infura)
# - BASE_SEPOLIA_RPC_URL
# - ETHERSCAN_API_KEY
```

### 2. Get Testnet Tokens (10 minutes)
```bash
# Sepolia ETH (need >1 ETH)
# https://sepoliafaucet.com
# https://www.alchemy.com/faucets/ethereum-sepolia

# Base Sepolia ETH (need >1 ETH)
# https://faucet.quicknode.com/base/sepolia
# https://www.alchemy.com/faucets/base-sepolia
```

### 3. Critical Checkpoints
- **11:00 PM Tonight**: All contracts deployed ✅
- **5:00 AM Tomorrow**: Frontend working ✅
- **7:30 AM Tomorrow**: Demo video uploaded ✅
- **8:30 AM Tomorrow**: Submitted to ETHGlobal ✅

---

## 18-Hour Execution Plan

**Current Time**: 3:00 PM, Day 1
**Deadline**: 9:00 AM, Day 2
**Total Time**: 18 hours

### Phase 1: Smart Contracts (3:00 PM - 11:00 PM) - 8 hours

#### Hour 1-2: Setup (3:00 PM - 5:00 PM)
**Goal**: Working development environment

```bash
# 3:00-3:30 PM: Project initialization
cd contracts
pnpm init
pnpm add -D hardhat @nomicfoundation/hardhat-toolbox
pnpx hardhat init  # Select TypeScript project

# 3:30-4:00 PM: Install dependencies
pnpm add @layerzerolabs/lz-evm-oapp-v2 @layerzerolabs/lz-evm-protocol-v2
pnpm add @openzeppelin/contracts@5.0.0
pnpm add @uniswap/v4-core @uniswap/v4-periphery

# 4:00-4:30 PM: Configure hardhat
# Edit hardhat.config.ts with Sepolia and Base Sepolia networks

# 4:30-5:00 PM: Get testnet tokens (see Quick Start)
```

**Deliverable**: ✅ Hardhat project with all dependencies installed

---

#### Hour 3-5: Core Contracts (5:00 PM - 8:00 PM)
**Goal**: ZKK-OFT and Fixed Exchange contracts ready

**5:00-6:30 PM: ZKK-OFT Contract**
- Extend OFT from LayerZero
- Implement `mintWithCompose()` function
- Implement `lzCompose()` handler
- Add simple greed model (fixed multiplier is fine for demo)

**6:30-7:30 PM: Fixed Exchange Contract**
- 1:1 USDC redemption logic
- Collateral management
- Emergency pause

**7:30-8:00 PM: Quick unit tests**
```bash
pnpm hardhat test test/ZKK.test.ts
pnpm hardhat test test/FixedExchange.test.ts
```

**Deliverable**: ✅ Two core contracts tested locally

---

#### Hour 6-7: Deployment (8:00 PM - 9:00 PM)
**Goal**: Contracts deployed and verified on both chains

```bash
# 8:00-8:20 PM: Deploy Mock USDC
pnpm hardhat run scripts/deploy-usdc.ts --network sepolia
pnpm hardhat run scripts/deploy-usdc.ts --network baseSepolia

# 8:20-8:40 PM: Deploy ZKK-OFT
pnpm hardhat run scripts/deploy-zkk.ts --network sepolia
pnpm hardhat run scripts/deploy-zkk.ts --network baseSepolia

# 8:40-9:00 PM: Deploy Fixed Exchange + Configure LayerZero
pnpm hardhat run scripts/deploy-exchange.ts --network sepolia
pnpm hardhat run scripts/configure-layerzero.ts
```

**Deliverable**: ✅ Contracts deployed, addresses saved, LayerZero peers configured

**🛑 CHECKPOINT**: By 9:00 PM, you should have contract addresses!

---

#### Hour 8: Uniswap Hook (9:00 PM - 11:00 PM)
**Goal**: Hook deployed with dynamic fee working

**9:00-10:00 PM: Implement simplified Hook**
- `beforeSwap()` - calculate dynamic fee based on price deviation
- `afterSwap()` - record price
- Skip complex volatility calculation (add if time permits)

**10:00-10:30 PM: Deploy Hook**
```bash
pnpm hardhat run scripts/deploy-hook.ts --network sepolia
```

**10:30-11:00 PM: Initialize Pool**
```bash
# Initialize ZKK-USDC pool on Uniswap v4
# Add initial liquidity (e.g., 1000 ZKK + 1000 USDC)
pnpm hardhat run scripts/initialize-pool.ts --network sepolia
```

**Deliverable**: ✅ Uniswap v4 pool created with working hook

**🛑 CRITICAL CHECKPOINT**: By 11:00 PM, all smart contracts MUST be deployed!

---

### Phase 2: Frontend (11:00 PM - 5:00 AM) - 6 hours

#### Hour 10-11: Frontend Setup (11:00 PM - 1:00 AM)
**Goal**: Basic app with wallet connection

```bash
# 11:00-11:30 PM: Initialize Next.js frontend
pnpm create next-app@latest frontend --typescript --tailwind --app --no-src-dir
cd frontend
pnpm install

# 11:30 PM-12:00 AM: Install Web3 dependencies
pnpm add wagmi viem @rainbow-me/rainbowkit
pnpm add @tanstack/react-query

# 12:00-12:30 AM: Setup RainbowKit
# Configure wagmi with Sepolia and Base Sepolia
# Create app/providers.tsx for client-side providers

# 12:30-1:00 AM: Contract integration
# Create lib/contracts.ts with ABIs and addresses
# Create hooks/useZKKContract.ts hook
```

**Deliverable**: ✅ App loads, wallet connects, can read contract data

---

#### Hour 12-14: Core Features (1:00 AM - 3:00 AM)
**Goal**: Mint and Swap working

**1:00-1:45 AM: MintSimulator Component**
- Large "Simulate Off-Chain Transaction" button
- Generates txHash and calls mintWithCompose()
- Shows ZKK balance after minting

**1:45-2:30 AM: DualSwapInterface Component**
- Side-by-side: Fixed Pool vs Uniswap Pool
- Input amount, show expected output for each
- Swap buttons for both pools

**2:30-3:00 AM: Basic styling**
- Apply TailwindCSS
- Make it look decent but not fancy
- Focus on clear information display

**Deliverable**: ✅ Can mint ZKK and swap on both pools

---

#### Hour 15-16: Polish & Deploy (3:00 AM - 5:00 AM)
**Goal**: Frontend deployed and working end-to-end

**3:00-4:00 AM: ArbitrageDisplay + Testing**
- Simple component showing price in each pool
- Price differential
- "Arbitrage Opportunity!" if diff > 0.5%

**4:00-4:30 AM: End-to-end testing**
- Test complete flow: Connect → Mint → Swap (both pools) → Check prices

**4:30-5:00 AM: Deploy to Vercel**
```bash
# Install Vercel CLI if needed
pnpm add -g vercel

# Build and deploy
pnpm build
vercel --prod

# Or link to GitHub for auto-deployment
```

**Deliverable**: ✅ Working frontend deployed online (project-name.vercel.app)

**🛑 CRITICAL CHECKPOINT**: By 5:00 AM, must have deployable demo!

---

### Phase 3: Submission (5:00 AM - 9:00 AM) - 4 hours

#### Hour 17: Demo Video (5:00 AM - 6:30 AM)
**Goal**: 3-minute demo video uploaded

**5:00-5:30 AM: Prepare demo script** (see [Demo Video Script](#demo-video-script))

**5:30-6:15 AM: Record video**
- Record screen + voiceover
- Show frontend, transactions on Etherscan, LayerZero Scan
- Show code snippet of compose message

**6:15-6:30 AM: Upload to YouTube**
- Make unlisted video
- Copy link for submission

**Deliverable**: ✅ YouTube video link ready

---

#### Hour 18: Documentation (6:30 AM - 7:30 AM)
**Goal**: README and architecture diagram complete

**6:30-7:00 AM: Update README.md**
- Add deployed contract addresses
- Add transaction links
- Add demo video embed

**7:00-7:30 AM: Create architecture diagram**
- Use Excalidraw or draw.io
- Export as PNG, add to docs/

**Deliverable**: ✅ Professional README + diagram

---

#### Final Hour: Submission (7:30 AM - 9:00 AM)
**Goal**: Submit to all tracks

**7:30-8:00 AM: Verify everything**
- All contracts verified on Etherscan ✓
- Frontend deployed and working ✓
- Demo video uploaded ✓
- README has all links ✓
- Code pushed to GitHub ✓

**8:00-8:30 AM: ETHGlobal submission**
1. Submit to ETHGlobal portal
2. Add to LayerZero track
3. Add to Uniswap Foundation track

**8:30-8:45 AM: LayerZero feedback form**
- Submit developer feedback

**8:45-9:00 AM: Final buffer**

**Deliverable**: ✅ PROJECT SUBMITTED!

---

## Project Overview

**ZakoKen** is a dynamic fundraising stablecoin protocol for open-source projects. It combines LayerZero OFT and Uniswap v4 hooks to create a dual-liquidity mechanism that stabilizes token prices while maximizing project treasury value.

### Demo Objectives

**Core Features to Demonstrate**:
1. **LayerZero Integration**: Cross-chain stablecoin + Compose Messages for off-chain transaction metadata
2. **Uniswap v4 Hook**: Dynamic fee for stable-asset trading pool
3. **Dual-Pool Arbitrage**: Project-controlled fixed pool vs. market-driven Uniswap pool

**Prize Targets**:
- **Primary**: LayerZero ($20k) + Uniswap Foundation ($10k) = $30k
- **Optional**: Circle Arc ($4k) - only if time permits

---

## Technical Architecture

### Deployment Chains
```
Ethereum Sepolia (Primary)
├── ZKK-OFT Token
├── Fixed Exchange (1:1 USDC pool)
├── Uniswap v4 Hook
├── Uniswap v4 Pool (ZKK-USDC)
└── Mock USDC

Base Sepolia (Cross-chain)
├── ZKK-OFT Token
└── Mock USDC

Arc Public Testnet (Optional)
├── ZKK-OFT Token (standalone)
├── Fixed Exchange
└── Native USDC (Circle faucet)
```

**Note**: LayerZero doesn't support Arc yet. Cross-chain functionality only works between Sepolia ↔ Base Sepolia.

### Repository Structure
```
ZakoKen/ (monorepo)
├── contracts/              # Smart contracts (Hardhat)
│   ├── src/               # Solidity source files
│   ├── script/            # Deployment scripts
│   └── test/              # Contract tests
├── frontend/              # Next.js app (TypeScript)
│   ├── app/              # Next.js app directory
│   ├── components/       # React components
│   │   ├── hooks/        # Custom hooks
│   │   └── utils/        # Helpers
│   └── public/
└── docs/                  # Documentation
```

---

## Smart Contract Specifications

### 1. ZKK-OFT Token (`contracts/src/ZKK.sol`)

```solidity
contract ZKK is OFT {
    // Core functions
    function mintWithCompose(
        address to,
        uint256 amount,
        bytes32 txHash,
        bytes32 projectId
    ) external onlyOwner;

    function lzCompose(...) external override;

    // Simplified greed model (demo version)
    function applyGreedModel(address user, uint256 baseAmount)
        internal returns (uint256);
}
```

**Compose Message Structure**:
```solidity
struct ComposeMsg {
    bytes32 transactionHash;    // Simulated off-chain tx hash
    uint256 timestamp;          // Timestamp
    uint256 amount;             // Minted amount
    address recipient;          // Token recipient
    bytes32 projectId;          // Project identifier
    uint256 greedIndex;         // Greed multiplier
}
```

### 2. Fixed Exchange (`contracts/src/FixedExchange.sol`)

```solidity
contract FixedExchange {
    // 1:1 USDC redemption
    function redeem(uint256 zkkAmount) external;

    // Project treasury management
    function depositCollateral(uint256 amount) external;
    function withdrawCollateral(uint256 amount) external onlyOwner;
}
```

### 3. Uniswap v4 Hook (`contracts/src/ZakoKenHook.sol`)

```solidity
contract ZakoKenHook is BaseHook {
    // Dynamic fee calculation
    function beforeSwap(...) external returns (bytes4, BeforeSwapDelta, uint24);

    // Price recording and arbitrage detection
    function afterSwap(...) external returns (bytes4, int128);

    // Fee range: 0.01% - 2%, base fee 0.05%
}
```

---

## Frontend Design

### Single-Page Application Structure

```
┌─────────────────────────────────────────────────┐
│  Header: Connect Wallet (RainbowKit)           │
│  Network: Sepolia / Base Sepolia               │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│  Section 1: Mint Tokens                         │
│  ┌───────────────────────────────────────────┐  │
│  │  [Simulate Off-Chain Transaction] Button │  │
│  │  → Mints ZKK with compose message          │  │
│  │  → Shows balance: 100 ZKK                  │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│  Section 2: Dual Swap Interface                 │
│  ┌──────────────────┐  ┌──────────────────┐    │
│  │  Fixed Pool      │  │  Uniswap v4 Pool │    │
│  │  1:1 USDC        │  │  ~0.998 USDC     │    │
│  │  0% Fee ✓        │  │  0.05% Fee       │    │
│  │  [Swap]          │  │  [Swap]          │    │
│  └──────────────────┘  └──────────────────┘    │
│  Input: [100] ZKK                               │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│  Section 3: Arbitrage Display                   │
│  Price Diff: 0.2% 🔴 Arbitrage Opportunity!     │
│  [Trigger Arbitrage] (Project-controlled)       │
│  Recent Arbitrage: +0.2 USDC profit             │
└─────────────────────────────────────────────────┘
```

### Core Components
1. **MintSimulator** (`frontend/components/MintSimulator.tsx`)
2. **DualSwapInterface** (`frontend/components/DualSwapInterface.tsx`)
3. **ArbitrageDisplay** (`frontend/components/ArbitrageDisplay.tsx`)
4. **CrossChainBridge** (`frontend/components/CrossChainBridge.tsx`) (Optional)

---

## Demo Video Script

**Duration**: 3 minutes

```
00:00-00:30  Problem Introduction
             - Open-source project fundraising challenges
             - Traditional tokens suffer from pump & dump
             - Price instability

00:30-01:00  Solution
             - ZakoKen dynamic greed model
             - Dual-pool mechanism (fixed + dynamic)
             - Project as arbitrageur

01:00-02:30  Feature Demonstration
             1. Connect wallet
             2. Click "Simulate Transaction" → mint 100 ZKK
             3. View price comparison of both pools
             4. Redeem on fixed pool (1:1, zero fee)
             5. Show Uniswap pool dynamic fee
             6. Trigger arbitrage (project profits)
             7. Cross-chain transfer to Base Sepolia
             8. View compose message on LayerZero Scan

02:30-03:00  Technical Highlights
             - LayerZero compose message stores off-chain data
             - Uniswap v4 hook dynamic fees
             - Project maximizes treasury through arbitrage
```

---

## Submission Checklist

### LayerZero Track ($20k)
- [ ] ZKK-OFT contracts verified on Sepolia and Base Sepolia
- [ ] Cross-chain transaction recorded on LayerZero Scan
- [ ] Code walkthrough of compose message implementation
- [ ] Developer feedback form submitted

### Uniswap Foundation Track ($10k)
- [ ] Hook contract verified on Sepolia
- [ ] Pool initialization transaction hash
- [ ] Multiple swap transactions showing dynamic fees
- [ ] 3-minute demo video
- [ ] GitHub repo with README

### Circle Track (Optional $4k)
- [ ] Contracts deployed on Arc
- [ ] Using native USDC from Circle faucet
- [ ] Demonstrate programmable redemption logic
- [ ] Architecture diagram + demo video

---

## Resources

### Official Documentation
- **LayerZero V2**: https://docs.layerzero.network/v2
- **Uniswap v4**: https://docs.uniswap.org/contracts/v4
- **Circle Arc**: https://docs.arc.network
- **Hardhat**: https://hardhat.org/docs

### Testnet Faucets
- **Sepolia ETH**: https://sepoliafaucet.com
- **Base Sepolia ETH**: https://faucet.quicknode.com/base/sepolia
- **Circle USDC (Arc)**: https://faucet.circle.com

### Explorers
- **Sepolia Etherscan**: https://sepolia.etherscan.io
- **Base Sepolia**: https://sepolia.basescan.org
- **LayerZero Scan**: https://testnet.layerzeroscan.com
- **Arc Explorer**: https://explorer.arc-testnet.gelato.digital

---

## Troubleshooting

### Smart Contracts Not Deploying?
```bash
# Check gas price
cast gas-price --rpc-url $SEPOLIA_RPC_URL

# Check wallet balance
cast balance $DEPLOYER_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Verify nonce
cast nonce $DEPLOYER_ADDRESS --rpc-url $SEPOLIA_RPC_URL
```

### LayerZero Not Working?
- Check peer configuration: `setPeer()` on both chains
- Verify endpoint addresses in `.env`
- Ensure sufficient gas for cross-chain (add >0.1 ETH value)

### Uniswap Hook Failing?
- Hook address must match permission flags
- Consider fallback: Use Uniswap v3 or simple AMM
- Simplify hook logic to just basic fee calculation

### Frontend Not Connecting?
- Check RPC URLs in frontend config
- Verify contract ABIs are correct
- Test contract calls in Remix first

---

## Fallback Strategies

### If Behind at 11 PM
- Skip complex greed model, use fixed multiplier
- Deploy contracts anyway, explain in video

### If Behind at 3 AM
- Skip ArbitrageDisplay component
- Focus on MintSimulator + basic swap only

### If Behind at 5 AM
- Skip frontend deployment
- Record video using localhost
- Explain it works locally

### If Behind at 7 AM
- Use phone to record quick video
- Skip architecture diagram
- Just submit with basic README

---

## Success Criteria

### Must Have
- ✅ ZKK-OFT with compose message
- ✅ Cross-chain transfer Sepolia ↔ Base
- ✅ Fixed Exchange 1:1 redemption
- ✅ Uniswap v4 Hook with dynamic fee
- ✅ Dual-pool frontend interface
- ✅ 3-minute demo video

### Nice to Have
- ⭕ Automated arbitrage bot
- ⭕ Complex greed model
- ⭕ Arc deployment (Circle track)
- ⭕ Beautiful UI design

---

**Core Principle**: Better a working demo than a perfect plan!

**You've got 18 hours. Let's ship it! 🚀**
