# ZakoKen Protocol - Deployment Guide

## Table of Contents

1. [Pre-Deployment Checklist](#1-pre-deployment-checklist)
2. [Contract Deployment Steps](#2-contract-deployment-steps)
3. [LayerZero Configuration](#3-layerzero-configuration)
4. [Uniswap v4 Pool Setup](#4-uniswap-v4-pool-setup)
5. [Frontend Deployment](#5-frontend-deployment)
6. [Post-Deployment Testing](#6-post-deployment-testing)
7. [Hackathon Submission](#7-hackathon-submission)

---

## 1. Pre-Deployment Checklist

### 1.1 Required Accounts & Keys

✅ **Wallet Setup:**
- [ ] MetaMask or hardware wallet configured
- [ ] Private key exported and secured
- [ ] Testnet ETH obtained for target chains:
  - [ ] Sepolia ETH (0.5+ ETH)
  - [ ] Base Sepolia ETH (0.5+ ETH)

✅ **API Keys:**
- [ ] Alchemy/Infura RPC endpoints
- [ ] Etherscan API key (for contract verification)
- [ ] WalletConnect Project ID (frontend)
- [ ] Circle faucet access for Base Sepolia

✅ **Test Tokens:**
- [ ] Test USDC on Sepolia deployed or address obtained
- [ ] Native USDC on Arc from Circle faucet
- [ ] Sufficient USDC for initial liquidity (10,000+ USDC)

### 1.2 Environment Setup

Create `.env` file with all required variables:

```bash
# Deployer Wallet
PRIVATE_KEY=0x...                              # DO NOT COMMIT!
DEPLOYER_ADDRESS=0x...                         # Your wallet address

# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY

# Block Explorers
ETHERSCAN_API_KEY=YOUR_KEY
BASESCAN_API_KEY=YOUR_KEY

# LayerZero Endpoints (Testnet)
LZ_ENDPOINT_SEPOLIA=0x6EDCE65403992e310A62460808c4b910D972f10f
LZ_ENDPOINT_BASE_SEPOLIA=0x6EDCE65403992e310A62460808c4b910D972f10f

# LayerZero Chain IDs (EIDs)
LZ_EID_SEPOLIA=40161
LZ_EID_BASE_SEPOLIA=40245

# Uniswap v4 (Sepolia only)
UNISWAP_V4_POOL_MANAGER=0x...                  # Official deployment
UNISWAP_V4_POSITION_MANAGER=0x...

# Test USDC Addresses
USDC_SEPOLIA=0x...                             # Deploy or use existing
USDC_BASE_SEPOLIA=0x...                        # Deploy or use existing

# Project Configuration
PROJECT_TREASURY=0x...                          # Treasury wallet address
PROJECT_ID=0x...                                # keccak256("zakoken-demo")

# Frontend (for production build)
VITE_WALLET_CONNECT_PROJECT_ID=YOUR_WC_ID
VITE_ALCHEMY_API_KEY=YOUR_KEY
VITE_ZKK_ADDRESS_SEPOLIA=                      # Fill after deployment
VITE_FIXED_EXCHANGE_SEPOLIA=                   # Fill after deployment
```

### 1.3 Code Preparation

```bash
# Ensure all code is committed
git status
git add .
git commit -m "Pre-deployment: Final code review"

# Run all tests
pnpm hardhat test

# Check gas usage
REPORT_GAS=true pnpm hardhat test

# Security checks (if slither is installed)
# slither .

# Format code
pnpm prettier --write "contracts/**/*.sol"
pnpm prettier --write "scripts/**/*.ts"
pnpm prettier --write "test/**/*.ts"
```

---

## 2. Contract Deployment Steps

### 2.1 Deploy Mock USDC (If Needed)

**File:** `contracts/MockUSDC.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockUSDC is ERC20, Ownable {
    constructor() ERC20("Mock USDC", "USDC") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 10**6); // 1M USDC
    }
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
```

**File:** `scripts/deploy-usdc.ts`

```typescript
import { ethers } from "hardhat";

async function main() {
  console.log("Deploying Mock USDC...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const MockUSDC = await ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();

  const address = await usdc.getAddress();
  console.log("Mock USDC deployed to:", address);
  
  // Mint initial test tokens
  const mintAmount = 10000n * 10n**6n; // 10,000 USDC
  await usdc.mint(deployer.address, mintAmount);
  console.log("Minted 10,000 USDC to deployer");

  return address;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

**Deploy:**

```bash
# Deploy on Sepolia
pnpm hardhat run scripts/deploy-usdc.ts --network sepolia

# Save address to .env
export USDC_SEPOLIA=0x...

# Verify contract
pnpm hardhat verify --network sepolia $USDC_SEPOLIA
```

### 2.2 Deploy ZKK-OFT Token

**File:** `scripts/deploy-zkk.ts`

```typescript
import { ethers } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
  const network = await ethers.provider.getNetwork();
  console.log("Deploying ZKK-OFT to:", network.name);

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)));

  // Get LayerZero endpoint for current network
  let lzEndpoint: string;
  if (network.chainId === 11155111n) { // Sepolia
    lzEndpoint = process.env.LZ_ENDPOINT_SEPOLIA!;
  } else if (network.chainId === 46341n) { // Base Sepolia (example)
    lzEndpoint = process.env.LZ_ENDPOINT_ARC!;
  } else {
    throw new Error("Unsupported network");
  }

  console.log("LayerZero Endpoint:", lzEndpoint);

  const ZKK = await ethers.getContractFactory("ZKK");
  const zkk = await ZKK.deploy(
    "ZakoKen",
    "ZKK",
    lzEndpoint,
    deployer.address
  );

  await zkk.waitForDeployment();
  const address = await zkk.getAddress();

  console.log("ZKK-OFT deployed to:", address);
  console.log("Owner:", await zkk.owner());
  console.log("Project start time:", await zkk.projectStartTime());

  // Save deployment info
  console.log("\nAdd to .env:");
  console.log(`ZKK_${network.name.toUpperCase()}=${address}`);

  return address;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

**Deploy on both chains:**

```bash
# 1. Deploy on Sepolia (Primary Chain - with Uniswap v4)
pnpm hardhat run scripts/deploy-zkk.ts --network sepolia

export ZKK_SEPOLIA=0x...

# Verify contract
pnpm hardhat verify --network sepolia \
  $ZKK_SEPOLIA \
  "ZakoKen" \
  "ZKK" \
  $LZ_ENDPOINT_SEPOLIA \
  $DEPLOYER_ADDRESS

# 2. Deploy on Base Sepolia (Secondary Chain - Circle's L1)
pnpm hardhat run scripts/deploy-zkk.ts --network arc

export ZKK_ARC=0x...

# Verify contract (check Arc documentation for verification)
```

### 2.3 Deploy Fixed Exchange Contract

**File:** `contracts/script/DeployFixedExchange.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FixedExchange.sol";

contract DeployFixedExchange is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address zknToken = vm.envAddress("ZKK_SEPOLIA");
        address usdcToken = vm.envAddress("USDC_SEPOLIA");
        address treasury = vm.envAddress("PROJECT_TREASURY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        FixedExchange exchange = new FixedExchange(
            zknToken,
            usdcToken,
            treasury,
            deployer
        );
        
        console.log("FixedExchange deployed at:", address(exchange));
        
        // Approve and deposit initial collateral
        IERC20(usdcToken).approve(address(exchange), 10000 * 10**6); // 10,000 USDC
        exchange.depositCollateral(10000 * 10**6);
        console.log("Initial collateral deposited: 10,000 USDC");
        
        vm.stopBroadcast();
    }
}
```

**Deploy:**

```bash
forge script script/DeployFixedExchange.s.sol:DeployFixedExchange \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

export FIXED_EXCHANGE_SEPOLIA=0x...
```

### 2.4 Deploy Uniswap v4 Hook

**File:** `contracts/script/DeployUniswapHook.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/UniswapHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";

contract DeployUniswapHook is Script {
    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManager = vm.envAddress("UNISWAP_V4_POOL_MANAGER");
        address fixedExchange = vm.envAddress("FIXED_EXCHANGE_SEPOLIA");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Calculate correct hook address with CREATE2
        // Hook address must have correct prefix based on permissions
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG
        );
        
        // Deploy with CREATE2 to get correct address
        // This requires a factory contract or manual salt calculation
        // For demo, we'll use direct deployment
        
        ZakoKenHook hook = new ZakoKenHook(
            IPoolManager(poolManager),
            fixedExchange
        );
        
        console.log("ZakoKenHook deployed at:", address(hook));
        console.log("Hook address flags:", uint160(address(hook)));
        
        vm.stopBroadcast();
        
        return address(hook);
    }
}
```

**Deploy:**

```bash
forge script script/DeployUniswapHook.s.sol:DeployUniswapHook \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

export ZAKOKEN_HOOK_SEPOLIA=0x...
```

### 2.5 Deploy Arbitrage Bot Contract

**File:** `contracts/script/DeployArbitrageBot.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ArbitrageBot.sol";

contract DeployArbitrageBot is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address zknToken = vm.envAddress("ZKK_SEPOLIA");
        address usdcToken = vm.envAddress("USDC_SEPOLIA");
        address fixedExchange = vm.envAddress("FIXED_EXCHANGE_SEPOLIA");
        address uniswapRouter = vm.envAddress("UNISWAP_V4_SWAP_ROUTER");
        
        vm.startBroadcast(deployerPrivateKey);
        
        ArbitrageBot bot = new ArbitrageBot(
            zknToken,
            usdcToken,
            fixedExchange,
            uniswapRouter,
            deployer
        );
        
        console.log("ArbitrageBot deployed at:", address(bot));
        
        vm.stopBroadcast();
    }
}
```

**Deploy:**

```bash
forge script script/DeployArbitrageBot.s.sol:DeployArbitrageBot \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

export ARBITRAGE_BOT_SEPOLIA=0x...
```

---

## 3. LayerZero Configuration

### 3.1 Set Trusted Peers

Connect all deployed ZKK-OFT contracts across chains.

**File:** `contracts/script/ConfigureLayerZero.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ZKK-OFT.sol";

contract ConfigureLayerZero is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address zkkSepolia = vm.envAddress("ZKK_SEPOLIA");
        address zkkArc = vm.envAddress("ZKK_ARC");
        
        uint32 eidSepolia = uint32(vm.envUint("LZ_EID_SEPOLIA"));
        uint32 eidArc = uint32(vm.envUint("LZ_EID_ARC"));
        
        // Configure Sepolia -> Arc
        vm.startBroadcast(deployerPrivateKey);
        
        ZKK(zkkSepolia).setPeer(
            eidArc,
            bytes32(uint256(uint160(zkkArc)))
        );
        console.log("Sepolia -> Arc peer set");
        
        vm.stopBroadcast();
        
        // Configure Arc -> Sepolia (switch RPC)
        vm.createSelectFork(vm.envString("ARC_RPC_URL"));
        vm.startBroadcast(deployerPrivateKey);
        
        ZKK(zkkArc).setPeer(
            eidSepolia,
            bytes32(uint256(uint160(zkkSepolia)))
        );
        console.log("Arc -> Sepolia peer set");
        
        vm.stopBroadcast();
        
        console.log("\nLayerZero cross-chain configuration complete!");
        console.log("Sepolia ZKK:", zkkSepolia);
        console.log("Arc ZKK:", zkkArc);
    }
}
```

**Execute:**

```bash
forge script script/ConfigureLayerZero.s.sol:ConfigureLayerZero \
  --broadcast
```

### 3.2 Configure DVN Security Stack

**Manual Configuration via cast:**

```bash
# Get LayerZero default DVN addresses
# Sepolia: 0x...
# Base Sepolia: 0x...

# Set enforced options (minimum confirmations, gas limits)
cast send $ZKK_SEPOLIA \
  "setEnforcedOptions((uint32,uint16,bytes)[])" \
  "[(40245,1,0x0003010011000000000000000000000000000493e0)]" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# The above sets:
# - destinationEid: 40245 (Base Sepolia)
# - msgType: 1 (SEND)
# - options: gas limit of 300,000
```

### 3.3 Test Cross-Chain Transfer

```bash
# Mint tokens on Sepolia
cast send $ZKK_SEPOLIA \
  "mintWithCompose(address,uint256,bytes32,bytes32)" \
  $DEPLOYER_ADDRESS \
  100000000000000000000 \
  0x$(openssl rand -hex 32) \
  0x$(echo -n "zakoken-demo" | sha256sum | cut -d' ' -f1) \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Send cross-chain to Base Sepolia
cast send $ZKK_SEPOLIA \
  "send((uint32,bytes32,uint256,uint256,bytes,bytes,bytes),address,bytes)" \
  "($LZ_EID_ARC,0x...,100000000000000000000,100000000000000000000,0x,0x,0x)" \
  $DEPLOYER_ADDRESS \
  0x \
  --value 0.01ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Monitor on LayerZero Scan
# https://testnet.layerzeroscan.com/

# Verify tokens received on Arc
cast call $ZKK_ARC \
  "balanceOf(address)(uint256)" \
  $DEPLOYER_ADDRESS \
  --rpc-url $ARC_RPC_URL
```

---

## 4. Uniswap v4 Pool Setup

### 4.1 Initialize Pool

**File:** `contracts/script/InitializeUniswapPool.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

contract InitializeUniswapPool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManager = vm.envAddress("UNISWAP_V4_POOL_MANAGER");
        address zknToken = vm.envAddress("ZKK_SEPOLIA");
        address usdcToken = vm.envAddress("USDC_SEPOLIA");
        address hook = vm.envAddress("ZAKOKEN_HOOK_SEPOLIA");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create pool key
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(zknToken),
            currency1: Currency.wrap(usdcToken),
            fee: 0, // Dynamic fee via hook
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        
        // Calculate sqrtPriceX96 for 1:1 price
        // For 1:1 price: sqrtPriceX96 = 2^96
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // sqrt(1) * 2^96
        
        // Initialize pool
        IPoolManager(poolManager).initialize(key, sqrtPriceX96, bytes(""));
        
        console.log("Pool initialized with 1:1 price");
        console.log("Currency0 (ZKK):", Currency.unwrap(key.currency0));
        console.log("Currency1 (USDC):", Currency.unwrap(key.currency1));
        
        vm.stopBroadcast();
    }
}
```

**Execute:**

```bash
forge script script/InitializeUniswapPool.s.sol:InitializeUniswapPool \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

### 4.2 Add Initial Liquidity

```bash
# Use Uniswap v4 Position Manager

# 1. Approve tokens
cast send $ZKK_SEPOLIA \
  "approve(address,uint256)" \
  $UNISWAP_V4_POSITION_MANAGER \
  1000000000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

cast send $USDC_SEPOLIA \
  "approve(address,uint256)" \
  $UNISWAP_V4_POSITION_MANAGER \
  10000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# 2. Add liquidity (via Position Manager)
# This requires using the Position Manager's mint function
# See Uniswap v4 docs for exact parameters
```

---

## 5. Frontend Deployment

### 5.1 Update Configuration

**File:** `frontend/src/utils/contracts.ts`

```typescript
export const CONTRACTS = {
  sepolia: {
    ZKK: '0x...', // ZKK_SEPOLIA
    FIXED_EXCHANGE: '0x...', // FIXED_EXCHANGE_SEPOLIA
    USDC: '0x...', // USDC_SEPOLIA
    ARBITRAGE_BOT: '0x...', // ARBITRAGE_BOT_SEPOLIA
  },
  baseSepolia: {
    ZKK: '0x...', // ZKK_ARC
    USDC: '0x...', // USDC_ARC
  },
  // ... other chains
};

export const UNISWAP_V4 = {
  sepolia: {
    POOL_MANAGER: '0x...',
    SWAP_ROUTER: '0x...',
    POSITION_MANAGER: '0x...',
  },
};
```

### 5.2 Build and Deploy

```bash
cd frontend

# Install dependencies
pnpm install

# Build for production
pnpm build

# Deploy to Vercel
vercel --prod

# Or deploy to GitHub Pages
# npm install -g gh-pages
# gh-pages -d dist

# Or use Netlify/other hosting
```

### 5.3 Configure Domain

- **Vercel:** Custom domain settings in dashboard
- **GitHub Pages:** Set up custom domain in repository settings
- **Alternative:** Use testnet.zakoken.app for demo

---

## 6. Post-Deployment Testing

### 6.1 Smoke Tests

**Test 1: Mint Tokens**

```bash
# Mint 100 ZKK tokens
cast send $ZKK_SEPOLIA \
  "mintWithCompose(address,uint256,bytes32,bytes32)" \
  $DEPLOYER_ADDRESS \
  100000000000000000000 \
  0x$(openssl rand -hex 32) \
  0x$(echo -n "test-project" | sha256sum | cut -d' ' -f1) \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Verify balance
cast call $ZKK_SEPOLIA \
  "balanceOf(address)(uint256)" \
  $DEPLOYER_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL
```

**Test 2: Fixed Pool Redemption**

```bash
# Approve ZKK
cast send $ZKK_SEPOLIA \
  "approve(address,uint256)" \
  $FIXED_EXCHANGE_SEPOLIA \
  50000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Redeem 50 ZKK for USDC
cast send $FIXED_EXCHANGE_SEPOLIA \
  "redeem(uint256)" \
  50000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Check USDC received
cast call $USDC_SEPOLIA \
  "balanceOf(address)(uint256)" \
  $DEPLOYER_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL
```

**Test 3: Cross-Chain Transfer**

```bash
# Send 25 ZKK from Sepolia to Base Sepolia
# (Use frontend or cast as shown in section 3.3)

# Verify on LayerZero Scan
# https://testnet.layerzeroscan.com/

# Check balance on Arc
cast call $ZKK_ARC \
  "balanceOf(address)(uint256)" \
  $DEPLOYER_ADDRESS \
  --rpc-url $ARC_RPC_URL
```

**Test 4: Uniswap Swap**

```bash
# Swap ZKK for USDC on Uniswap v4
# (Use frontend or Position Manager)

# Check pool state
cast call $UNISWAP_V4_POOL_MANAGER \
  "getSlot0(bytes32)" \
  0x... \
  --rpc-url $SEPOLIA_RPC_URL
```

### 6.2 Integration Tests

**Test Full User Flow:**

1. Connect wallet to frontend
2. Mint tokens via simulate button
3. View token balance
4. Attempt swap on fixed pool
5. Attempt swap on Uniswap pool
6. Compare prices and fees
7. Cross-chain transfer to Base
8. Verify tokens on destination

### 6.3 Performance Tests

- Measure gas costs for each operation
- Test under different network conditions
- Verify compose message handling
- Check arbitrage bot triggers

---

## 7. Hackathon Submission

### 7.1 Required Materials

✅ **GitHub Repository:**
- [ ] Clean, well-organized code structure
- [ ] Comprehensive README.md with:
  - [ ] Project description
  - [ ] Architecture diagram
  - [ ] Setup instructions
  - [ ] Deployed contract addresses
  - [ ] Demo video link
- [ ] All contracts verified on Etherscan
- [ ] Frontend deployment link

✅ **Contract Addresses Document:**

```markdown
# ZakoKen Protocol - Deployed Contracts

## Ethereum Sepolia (Primary Chain)
- ZKK Token: [0x...](https://sepolia.etherscan.io/address/0x...)
- Fixed Exchange: [0x...](https://sepolia.etherscan.io/address/0x...)
- Arbitrage Bot: [0x...](https://sepolia.etherscan.io/address/0x...)
- Uniswap v4 Hook: [0x...](https://sepolia.etherscan.io/address/0x...)
- Uniswap v4 ZKK-USDC Pool: [0x...]

## Base Sepolia (Circle's L1)
- ZKK Token: [0x...](https://explorer.arc-testnet.gelato.digital/address/0x...)
- Native USDC: [0x...](https://explorer.arc-testnet.gelato.digital/address/0x...)

## Test Transactions
- Mint with compose: [0x...](https://sepolia.etherscan.io/tx/0x...)
- Cross-chain Sepolia→Arc: [0x...](https://testnet.layerzeroscan.com/...)
- Fixed pool swap: [0x...](https://sepolia.etherscan.io/tx/0x...)
- Uniswap v4 swap: [0x...](https://sepolia.etherscan.io/tx/0x...)
- Arbitrage execution: [0x...](https://sepolia.etherscan.io/tx/0x...)
```

✅ **Demo Video (3 minutes max):**

**Script Outline:**
1. **Introduction (20 seconds)**
   - Problem: Unsustainable open-source fundraising
   - Solution: ZakoKen dynamic greed model

2. **Architecture (40 seconds)**
   - LayerZero OFT for cross-chain
   - Dual liquidity pools (Fixed + Uniswap v4)
   - Compose messages for off-chain data
   - Dynamic greed model adjustments

3. **Demo (90 seconds)**
   - Connect wallet
   - Mint tokens (show compose message)
   - Compare two pools (fixed vs dynamic)
   - Execute swap on fixed pool
   - Show arbitrage opportunity
   - Cross-chain transfer to Arc
   - Verify on Arc using Circle's native USDC

4. **Innovation & Impact (30 seconds)**
   - Sustainable fundraising for open-source
   - Treasury optimization through arbitrage
   - Fair token distribution
   - Cross-chain accessibility

**Recording Tools:**
- Loom (https://loom.com)
- OBS Studio
- Screen recording + webcam

**Video Checklist:**
- [ ] Clear audio
- [ ] Visible UI/transactions
- [ ] Smooth transitions
- [ ] Professional presentation
- [ ] Upload to YouTube
- [ ] Add to GitHub README

### 7.2 Sponsor-Specific Requirements

**LayerZero Track:**

✅ Required:
- [ ] Compose message implementation shown in code
- [ ] Cross-chain transaction on LayerZero Scan
- [ ] Developer feedback form submitted
- [ ] Explain extension of OFT standard

**Uniswap Foundation Track:**

✅ Required:
- [ ] Hook contract code with beforeSwap/afterSwap
- [ ] Pool initialization transaction
- [ ] Swap transactions showing dynamic fee
- [ ] Explain stable-asset AMM logic

**Circle Track (Optional):**

✅ Required:
- [ ] Contracts deployed on Base Sepolia
- [ ] USDC integration demonstrated
- [ ] Architecture diagram included
- [ ] Cross-chain USDC flow (if using CCTP)

### 7.3 Submission Checklist

**ETHGlobal Portal:**
- [ ] Project submitted on ETHGlobal website
- [ ] All team members added
- [ ] Tracks selected (LayerZero, Uniswap, Circle)
- [ ] Demo video embedded
- [ ] GitHub link added
- [ ] Description and tech stack complete

**GitHub Repository:**
- [ ] README.md comprehensive
- [ ] Code commented and clean
- [ ] .env.example provided
- [ ] License file (MIT recommended)
- [ ] Architecture docs linked
- [ ] Deployment guide accessible

**Demo Preparation:**
- [ ] Frontend deployed and accessible
- [ ] Test transactions prepared
- [ ] Contracts verified on explorers
- [ ] LayerZero Scan links ready
- [ ] Presentation slides (optional)

### 7.4 Judging Criteria

**Technical Implementation (40%):**
- Correct LayerZero OFT usage
- Proper Uniswap v4 hook implementation
- Code quality and testing
- Security considerations

**Innovation (30%):**
- Novel use of compose messages
- Dynamic greed model creativity
- Dual-pool arbitrage mechanism
- Cross-chain functionality

**Functionality (20%):**
- Working demo on testnet
- All core features operational
- User experience quality
- Documentation completeness

**Presentation (10%):**
- Clear problem/solution explanation
- Effective demo video
- Professional materials
- Team communication

---

## 8. Post-Hackathon Actions

### 8.1 Immediate Follow-Ups

**Within 24 hours:**
- [ ] Thank sponsors on Twitter
- [ ] Share demo video
- [ ] Join Discord/Telegram communities
- [ ] Network with judges and mentors

**Within 1 week:**
- [ ] Gather feedback
- [ ] Document learnings
- [ ] Plan next iteration
- [ ] Apply for grants/accelerators

### 8.2 Mainnet Preparation (If Proceeding)

**Security:**
- [ ] Professional audit (Quantstamp, OpenZeppelin, etc.)
- [ ] Bug bounty program
- [ ] Multi-sig for admin functions
- [ ] Emergency pause mechanisms tested

**Legal:**
- [ ] Token legal opinion
- [ ] Terms of service
- [ ] Privacy policy
- [ ] Regulatory compliance check

**Technical:**
- [ ] Gas optimization
- [ ] Oracle integration for prices
- [ ] Monitoring and alerts
- [ ] Incident response plan

**Community:**
- [ ] Documentation website
- [ ] User guides
- [ ] Developer SDK
- [ ] Community channels

---

## 9. Emergency Procedures

### 9.1 Common Issues

**Issue:** Transaction Failing
```bash
# Check gas price
cast gas-price --rpc-url $SEPOLIA_RPC_URL

# Increase gas limit
cast send ... --gas-limit 500000

# Check nonce
cast nonce $DEPLOYER_ADDRESS --rpc-url $SEPOLIA_RPC_URL
```

**Issue:** LayerZero Message Not Delivered
```bash
# Check on LayerZero Scan
# https://testnet.layerzeroscan.com/

# Retry delivery (if verified but not delivered)
cast send $LZ_ENDPOINT_SEPOLIA \
  "retryPayload(...)" \
  ... \
  --rpc-url $SEPOLIA_RPC_URL

# Check DVN config
cast call $ZKK_SEPOLIA \
  "getConfig(...)" \
  ...
```

**Issue:** Uniswap Pool Not Working
```bash
# Verify hook address format
# Hook address must match permission flags

# Check pool initialization
cast call $UNISWAP_V4_POOL_MANAGER \
  "getSlot0(bytes32)" \
  $POOL_ID

# Verify liquidity
cast call $UNISWAP_V4_POOL_MANAGER \
  "getLiquidity(bytes32)" \
  $POOL_ID
```

### 9.2 Rollback Procedures

**If Critical Bug Found:**

1. **Pause all contracts:**
```bash
cast send $FIXED_EXCHANGE_SEPOLIA \
  "pause()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

2. **Disable cross-chain:**
```bash
# Remove peers temporarily
cast send $ZKK_SEPOLIA \
  "setPeer(uint32,bytes32)" \
  40245 \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL
```

3. **Notify users via:**
- Frontend banner
- Twitter announcement
- Discord message

4. **Fix and redeploy:**
- Deploy new contracts
- Migrate state if necessary
- Resume operations after testing

---

## 10. Contact and Support

### 10.1 Hackathon Support

**ETHGlobal:**
- Discord: Join #help channel
- Mentors: Available at hacker house
- Emergency: Contact organizers directly

**Sponsors:**
- LayerZero: Discord #devs channel
- Uniswap: Telegram developer group
- Circle: Support email in bounty description

### 10.2 Technical Resources

**Documentation:**
- LayerZero: https://docs.layerzero.network
- Uniswap v4: https://docs.uniswap.org/contracts/v4
- Foundry: https://book.getfoundry.sh

**Community:**
- LayerZero Discord
- Uniswap Discord
- Ethereum Stack Exchange

---

## Appendix A: Complete Deployment Script

**File:** `contracts/script/DeployAll.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ZKK-OFT.sol";
import "../src/FixedExchange.sol";
import "../src/UniswapHook.sol";
import "../src/ArbitrageBot.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ZKK-OFT
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT_SEPOLIA");
        ZKK zkn = new ZKK("ZakoKen", "ZKK", lzEndpoint, deployer);
        console.log("ZKK deployed:", address(zkn));
        
        // 2. Deploy Fixed Exchange
        address usdc = vm.envAddress("USDC_SEPOLIA");
        address treasury = vm.envAddress("PROJECT_TREASURY");
        FixedExchange exchange = new FixedExchange(
            address(zkn),
            usdc,
            treasury,
            deployer
        );
        console.log("FixedExchange deployed:", address(exchange));
        
        // 3. Deploy Uniswap Hook
        address poolManager = vm.envAddress("UNISWAP_V4_POOL_MANAGER");
        ZakoKenHook hook = new ZakoKenHook(
            IPoolManager(poolManager),
            address(exchange)
        );
        console.log("ZakoKenHook deployed:", address(hook));
        
        // 4. Deploy Arbitrage Bot
        address swapRouter = vm.envAddress("UNISWAP_V4_SWAP_ROUTER");
        ArbitrageBot bot = new ArbitrageBot(
            address(zkn),
            usdc,
            address(exchange),
            swapRouter,
            deployer
        );
        console.log("ArbitrageBot deployed:", address(bot));
        
        vm.stopBroadcast();
        
        // Save addresses to file
        string memory json = string(abi.encodePacked(
            '{"zkn":"', vm.toString(address(zkn)), '",',
            '"fixedExchange":"', vm.toString(address(exchange)), '",',
            '"hook":"', vm.toString(address(hook)), '",',
            '"arbitrageBot":"', vm.toString(address(bot)), '"}'
        ));
        
        vm.writeFile("deployments/sepolia.json", json);
        console.log("Addresses saved to deployments/sepolia.json");
    }
}
```

**Execute complete deployment:**

```bash
mkdir -p deployments
forge script script/DeployAll.s.sol:DeployAll \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

---

## Appendix B: Verification Commands

```bash
# Verify ZKK-OFT
forge verify-contract \
  $ZKK_SEPOLIA \
  src/ZKK-OFT.sol:ZKK \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain sepolia \
  --constructor-args $(cast abi-encode "constructor(string,string,address,address)" "ZakoKen" "ZKK" $LZ_ENDPOINT_SEPOLIA $DEPLOYER_ADDRESS)

# Verify Fixed Exchange
forge verify-contract \
  $FIXED_EXCHANGE_SEPOLIA \
  src/FixedExchange.sol:FixedExchange \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain sepolia \
  --constructor-args $(cast abi-encode "constructor(address,address,address,address)" $ZKK_SEPOLIA $USDC_SEPOLIA $PROJECT_TREASURY $DEPLOYER_ADDRESS)

# Verify Uniswap Hook
forge verify-contract \
  $ZAKOKEN_HOOK_SEPOLIA \
  src/UniswapHook.sol:ZakoKenHook \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain sepolia \
  --constructor-args $(cast abi-encode "constructor(address,address)" $UNISWAP_V4_POOL_MANAGER $FIXED_EXCHANGE_SEPOLIA)
```

---

**Document Version:** 1.0  
**Last Updated:** November 22, 2025  