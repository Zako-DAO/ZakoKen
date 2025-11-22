# ZakoKen Protocol - Development Guide

## Table of Contents

1. [Development Environment Setup](#1-development-environment-setup)
2. [Smart Contract Development](#2-smart-contract-development)
3. [Frontend Development](#3-frontend-development)
4. [Testing Guide](#4-testing-guide)
5. [Integration Points](#5-integration-points)
6. [Common Issues & Solutions](#6-common-issues--solutions)

---

## 1. Development Environment Setup

### 1.1 Prerequisites

**Required Software:**
```bash
# Node.js (v18+)
node --version  # Should be v18.0.0 or higher

# pnpm (package manager)
npm install -g pnpm

# Hardhat (will be installed per project)
# No global installation needed

# Git
git --version
```

**Required Accounts:**
- Ethereum wallet (MetaMask or similar)
- Testnet ETH from faucets
- GitHub account
- (Optional) Alchemy/Infura API key

### 1.2 Project Structure

```
zakoken/
├── contracts/                 # Smart contracts
│   ├── ZKK-OFT.sol           # Main OFT token
│   ├── FixedExchange.sol     # Fixed rate pool
│   ├── UniswapHook.sol       # Uniswap v4 hook
│   ├── ArbitrageBot.sol      # Arbitrage automation
│   └── interfaces/           # Contract interfaces
├── scripts/                   # Deployment scripts
│   ├── deploy-zkk.ts         # Deploy ZKK token
│   ├── deploy-exchange.ts    # Deploy fixed exchange
│   ├── deploy-hook.ts        # Deploy Uniswap hook
│   └── configure-lz.ts       # LayerZero setup
├── test/                      # Contract tests
│   ├── ZKK.test.ts           # ZKK token tests
│   ├── FixedExchange.test.ts
│   └── UniswapHook.test.ts
├── frontend/                  # React application
│   ├── src/
│   │   ├── components/       # UI components
│   │   ├── hooks/            # Custom React hooks
│   │   ├── utils/            # Utilities
│   │   └── App.tsx           # Main app
│   ├── public/
│   └── package.json
├── docs/                      # Documentation
├── hardhat.config.ts         # Hardhat configuration
├── package.json              # Project dependencies
├── .env.example              # Environment template
└── README.md
```

### 1.3 Initial Setup

```bash
# Clone repository
git clone https://github.com/[username]/zakoken.git
cd zakoken

# Install dependencies
pnpm install

# Install Hardhat and plugins
pnpm add -D hardhat @nomicfoundation/hardhat-toolbox

# Initialize Hardhat (if not already initialized)
# pnpm hardhat init

# Copy environment template
cp .env.example .env

# Edit .env with your values
# See section 1.4 for required variables
```

### 1.4 Environment Variables

Create a `.env` file in the project root:

```bash
# Private Keys (NEVER commit these!)
PRIVATE_KEY=your_wallet_private_key_here

# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY

# Block Explorers (for verification)
ETHERSCAN_API_KEY=your_etherscan_key
BASESCAN_API_KEY=your_basescan_key

# LayerZero Endpoints (testnet)
LAYERZERO_SEPOLIA_ENDPOINT=0x6EDCE65403992e310A62460808c4b910D972f10f
LAYERZERO_BASE_SEPOLIA_ENDPOINT=0x6EDCE65403992e310A62460808c4b910D972f10f

# Uniswap v4 (Sepolia only)
UNISWAP_V4_POOL_MANAGER=0x...  # Official Sepolia deployment

# Test USDC Addresses
USDC_SEPOLIA=0x...  # Deploy or use existing
USDC_BASE_SEPOLIA=0x...  # Deploy or use existing

# Frontend (for development)
VITE_WALLET_CONNECT_PROJECT_ID=your_wc_project_id
VITE_ALCHEMY_API_KEY=your_alchemy_key
```

### 1.5 Get Testnet Tokens

**Sepolia ETH:**
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia
- https://faucet.quicknode.com/ethereum/sepolia

**Base Sepolia ETH:**
- https://www.alchemy.com/faucets/base-sepolia
- https://faucet.quicknode.com/base/sepolia
- https://docs.base.org/tools/network-faucets

**Test USDC:**
- Sepolia: Deploy mock USDC or use existing test USDC contracts
- Base Sepolia: Deploy mock USDC or use bridged test USDC

---

## 2. Smart Contract Development

### 2.1 ZKK-OFT Contract

**File:** `contracts/ZKK-OFT.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";

/**
 * @title ZakoKen Token (ZKK)
 * @notice Omnichain fungible token with dynamic greed model
 * @dev Implements LayerZero OFT standard with compose messages
 */
contract ZKK is OFT {
    using OFTComposeMsgCodec for bytes;

    // ============ State Variables ============

    /// @notice Off-chain transaction data structure
    struct OffChainTransaction {
        bytes32 transactionHash;
        uint256 timestamp;
        uint256 amount;
        address recipient;
        bytes32 projectId;
        uint256 greedIndex;
    }

    /// @notice Greed model parameters
    struct GreedModel {
        uint256 baseMultiplier;      // Base greed multiplier (1e18 = 1x)
        uint256 velocityThreshold;   // Transaction velocity threshold
        uint256 decayRate;           // Time decay rate
        uint256 maxMultiplier;       // Maximum greed multiplier
        uint256 minMultiplier;       // Minimum greed multiplier
    }

    /// @notice Current greed index
    uint256 public currentGreedIndex;

    /// @notice Project start timestamp
    uint256 public immutable projectStartTime;

    /// @notice Greed model parameters
    GreedModel public greedModel;

    /// @notice Recent compose messages for velocity calculation
    uint256[] public recentMessageTimestamps;
    uint256 constant TIME_WINDOW = 1 hours;

    /// @notice Mapping of transaction hash to off-chain data
    mapping(bytes32 => OffChainTransaction) public offChainTransactions;

    /// @notice User concentration tracking
    mapping(address => uint256) public userTokenBalances;
    uint256 public totalMintedSupply;

    // ============ Events ============

    event OffChainTransactionRecorded(
        bytes32 indexed txHash,
        address indexed recipient,
        uint256 amount,
        uint256 greedIndex
    );

    event GreedIndexUpdated(uint256 oldIndex, uint256 newIndex);

    event ComposeMessageProcessed(
        bytes32 indexed guid,
        address indexed from,
        uint256 amount
    );

    // ============ Constructor ============

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        projectStartTime = block.timestamp;
        
        // Initialize greed model with default parameters
        greedModel = GreedModel({
            baseMultiplier: 1e18,        // 1x base
            velocityThreshold: 10,       // 10 tx per hour
            decayRate: 1e15,             // 0.001 per second
            maxMultiplier: 5e18,         // 5x max
            minMultiplier: 5e17          // 0.5x min
        });
        
        currentGreedIndex = greedModel.baseMultiplier;
    }

    // ============ External Functions ============

    /**
     * @notice Mint tokens with compose message
     * @param to Recipient address
     * @param amount Amount to mint
     * @param txHash Off-chain transaction hash
     * @param projectId Project identifier
     */
    function mintWithCompose(
        address to,
        uint256 amount,
        bytes32 txHash,
        bytes32 projectId
    ) external onlyOwner {
        // Apply greed model to determine actual mint amount
        uint256 adjustedAmount = applyGreedModel(to, amount);
        
        // Mint tokens
        _mint(to, adjustedAmount);
        
        // Record off-chain transaction
        offChainTransactions[txHash] = OffChainTransaction({
            transactionHash: txHash,
            timestamp: block.timestamp,
            amount: adjustedAmount,
            recipient: to,
            projectId: projectId,
            greedIndex: currentGreedIndex
        });

        // Update user balance tracking
        userTokenBalances[to] += adjustedAmount;
        totalMintedSupply += adjustedAmount;

        emit OffChainTransactionRecorded(txHash, to, adjustedAmount, currentGreedIndex);
    }

    /**
     * @notice Handle compose messages from LayerZero
     * @dev Called by LayerZero Endpoint after token transfer
     */
    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) external payable override {
        // Only endpoint can call
        require(msg.sender == address(endpoint), "ZKK: unauthorized");

        // Decode compose message
        (uint256 amountLD, bytes memory composeMsg) = _message.decodeMsgComposeMsg();
        
        // Decode off-chain transaction data
        OffChainTransaction memory txData = abi.decode(composeMsg, (OffChainTransaction));

        // Store transaction record
        offChainTransactions[txData.transactionHash] = txData;

        // Update greed model based on compose message
        updateGreedIndex(txData);

        emit ComposeMessageProcessed(_guid, _from, amountLD);
    }

    // ============ Internal Functions ============

    /**
     * @notice Apply greed model to calculate adjusted mint amount
     * @param user User address
     * @param baseAmount Base mint amount
     * @return Adjusted amount after applying greed model
     */
    function applyGreedModel(address user, uint256 baseAmount) internal returns (uint256) {
        // Calculate velocity-based multiplier
        uint256 velocity = calculateVelocity();
        uint256 velocityMultiplier = greedModel.baseMultiplier + 
            (velocity * greedModel.baseMultiplier) / greedModel.velocityThreshold;

        // Apply time decay
        uint256 timeSinceStart = block.timestamp - projectStartTime;
        uint256 decayFactor = 1e18 - (greedModel.decayRate * timeSinceStart);
        if (decayFactor < greedModel.minMultiplier) {
            decayFactor = greedModel.minMultiplier;
        }

        // Calculate concentration factor
        uint256 userRatio = totalMintedSupply > 0 
            ? (userTokenBalances[user] * 1e18) / totalMintedSupply
            : 0;
        uint256 concentrationFactor = 1e18 - (userRatio * userRatio) / 1e18;

        // Combine all factors
        uint256 finalMultiplier = (velocityMultiplier * decayFactor * concentrationFactor) / (1e18 * 1e18);

        // Clamp to min/max
        if (finalMultiplier > greedModel.maxMultiplier) {
            finalMultiplier = greedModel.maxMultiplier;
        }
        if (finalMultiplier < greedModel.minMultiplier) {
            finalMultiplier = greedModel.minMultiplier;
        }

        // Update current greed index
        uint256 oldIndex = currentGreedIndex;
        currentGreedIndex = finalMultiplier;
        emit GreedIndexUpdated(oldIndex, currentGreedIndex);

        // Calculate adjusted amount
        return (baseAmount * finalMultiplier) / 1e18;
    }

    /**
     * @notice Calculate transaction velocity (tx per hour)
     * @return Transaction velocity
     */
    function calculateVelocity() internal view returns (uint256) {
        uint256 count = 0;
        uint256 cutoff = block.timestamp - TIME_WINDOW;
        
        for (uint256 i = recentMessageTimestamps.length; i > 0; i--) {
            if (recentMessageTimestamps[i - 1] < cutoff) {
                break;
            }
            count++;
        }
        
        return count;
    }

    /**
     * @notice Update greed index based on new compose message
     * @param txData Off-chain transaction data
     */
    function updateGreedIndex(OffChainTransaction memory txData) internal {
        // Add timestamp to recent messages
        recentMessageTimestamps.push(txData.timestamp);

        // Clean old timestamps (keep only within TIME_WINDOW)
        uint256 cutoff = block.timestamp - TIME_WINDOW;
        while (recentMessageTimestamps.length > 0 && 
               recentMessageTimestamps[0] < cutoff) {
            // Remove first element
            for (uint256 i = 0; i < recentMessageTimestamps.length - 1; i++) {
                recentMessageTimestamps[i] = recentMessageTimestamps[i + 1];
            }
            recentMessageTimestamps.pop();
        }
    }

    // ============ Admin Functions ============

    /**
     * @notice Update greed model parameters
     * @param _baseMultiplier New base multiplier
     * @param _velocityThreshold New velocity threshold
     * @param _decayRate New decay rate
     * @param _maxMultiplier New max multiplier
     * @param _minMultiplier New min multiplier
     */
    function updateGreedModel(
        uint256 _baseMultiplier,
        uint256 _velocityThreshold,
        uint256 _decayRate,
        uint256 _maxMultiplier,
        uint256 _minMultiplier
    ) external onlyOwner {
        greedModel = GreedModel({
            baseMultiplier: _baseMultiplier,
            velocityThreshold: _velocityThreshold,
            decayRate: _decayRate,
            maxMultiplier: _maxMultiplier,
            minMultiplier: _minMultiplier
        });
    }

    // ============ View Functions ============

    /**
     * @notice Get current greed multiplier
     * @return Current multiplier (1e18 = 1x)
     */
    function getCurrentMultiplier() external view returns (uint256) {
        return currentGreedIndex;
    }

    /**
     * @notice Get off-chain transaction details
     * @param txHash Transaction hash
     * @return Transaction data
     */
    function getOffChainTransaction(bytes32 txHash) 
        external 
        view 
        returns (OffChainTransaction memory) 
    {
        return offChainTransactions[txHash];
    }
}
```

### 2.2 Fixed Rate Exchange Contract

**File:** `contracts/FixedExchange.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title FixedExchange
 * @notice 1:1 fixed rate exchange between ZKK and USDC
 * @dev Project-controlled pool for guaranteed redemption
 */
contract FixedExchange is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    /// @notice ZKK token contract
    IERC20 public immutable zknToken;

    /// @notice USDC token contract
    IERC20 public immutable usdcToken;

    /// @notice Project treasury address
    address public projectTreasury;

    /// @notice Total USDC collateral deposited
    uint256 public totalCollateral;

    /// @notice Total ZKK tokens redeemed
    uint256 public totalRedeemed;

    /// @notice Maximum redemption per transaction
    uint256 public maxRedemptionAmount;

    /// @notice Minimum collateral ratio (1e18 = 100%)
    uint256 public minCollateralRatio;

    // ============ Events ============

    event CollateralDeposited(address indexed depositor, uint256 amount);
    event CollateralWithdrawn(address indexed recipient, uint256 amount);
    event TokensRedeemed(address indexed user, uint256 zknAmount, uint256 usdcAmount);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event MaxRedemptionUpdated(uint256 oldMax, uint256 newMax);

    // ============ Constructor ============

    constructor(
        address _zknToken,
        address _usdcToken,
        address _projectTreasury,
        address _owner
    ) Ownable(_owner) {
        require(_zknToken != address(0), "Invalid ZKK address");
        require(_usdcToken != address(0), "Invalid USDC address");
        require(_projectTreasury != address(0), "Invalid treasury");

        zknToken = IERC20(_zknToken);
        usdcToken = IERC20(_usdcToken);
        projectTreasury = _projectTreasury;

        // Default: 1M tokens per redemption
        maxRedemptionAmount = 1_000_000 * 1e18;
        
        // Default: 100% collateral ratio required
        minCollateralRatio = 1e18;
    }

    // ============ External Functions ============

    /**
     * @notice Deposit USDC collateral to the pool
     * @param amount Amount of USDC to deposit
     */
    function depositCollateral(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");

        usdcToken.safeTransferFrom(msg.sender, address(this), amount);
        totalCollateral += amount;

        emit CollateralDeposited(msg.sender, amount);
    }

    /**
     * @notice Redeem ZKK tokens for USDC at 1:1 ratio
     * @param zknAmount Amount of ZKK to redeem
     */
    function redeem(uint256 zknAmount) external nonReentrant whenNotPaused {
        require(zknAmount > 0, "Amount must be > 0");
        require(zknAmount <= maxRedemptionAmount, "Exceeds max redemption");

        // Calculate USDC amount (1:1 ratio)
        uint256 usdcAmount = zknAmount / 1e18; // Assuming ZKK has 18 decimals, USDC has 6

        // Check sufficient collateral
        require(totalCollateral >= usdcAmount, "Insufficient collateral");

        // Check collateral ratio after redemption
        uint256 remainingCollateral = totalCollateral - usdcAmount;
        uint256 outstandingZkn = zknToken.totalSupply() - zknAmount;
        if (outstandingZkn > 0) {
            uint256 ratio = (remainingCollateral * 1e18 * 1e12) / outstandingZkn; // Adjust for decimals
            require(ratio >= minCollateralRatio, "Collateral ratio too low");
        }

        // Transfer ZKK from user
        zknToken.safeTransferFrom(msg.sender, address(this), zknAmount);

        // Burn ZKK tokens
        // Note: If ZKK has burn function, call it. Otherwise, keep in contract
        // For this demo, we'll just keep it in contract

        // Transfer USDC to user
        usdcToken.safeTransfer(msg.sender, usdcAmount);

        totalCollateral -= usdcAmount;
        totalRedeemed += zknAmount;

        emit TokensRedeemed(msg.sender, zknAmount, usdcAmount);
    }

    /**
     * @notice Withdraw excess collateral to treasury
     * @param amount Amount of USDC to withdraw
     */
    function withdrawCollateral(uint256 amount) external onlyOwner {
        require(amount <= totalCollateral, "Insufficient collateral");

        // Calculate required collateral for outstanding tokens
        uint256 outstandingZkn = zknToken.totalSupply();
        uint256 requiredCollateral = (outstandingZkn * minCollateralRatio) / (1e18 * 1e12);
        uint256 availableToWithdraw = totalCollateral > requiredCollateral 
            ? totalCollateral - requiredCollateral 
            : 0;

        require(amount <= availableToWithdraw, "Would breach collateral ratio");

        totalCollateral -= amount;
        usdcToken.safeTransfer(projectTreasury, amount);

        emit CollateralWithdrawn(projectTreasury, amount);
    }

    // ============ Admin Functions ============

    /**
     * @notice Update project treasury address
     * @param _newTreasury New treasury address
     */
    function updateTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid address");
        address oldTreasury = projectTreasury;
        projectTreasury = _newTreasury;
        emit TreasuryUpdated(oldTreasury, _newTreasury);
    }

    /**
     * @notice Update maximum redemption amount
     * @param _maxAmount New maximum amount
     */
    function updateMaxRedemption(uint256 _maxAmount) external onlyOwner {
        uint256 oldMax = maxRedemptionAmount;
        maxRedemptionAmount = _maxAmount;
        emit MaxRedemptionUpdated(oldMax, _maxAmount);
    }

    /**
     * @notice Update minimum collateral ratio
     * @param _ratio New ratio (1e18 = 100%)
     */
    function updateMinCollateralRatio(uint256 _ratio) external onlyOwner {
        require(_ratio >= 5e17, "Ratio must be >= 50%");
        minCollateralRatio = _ratio;
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ View Functions ============

    /**
     * @notice Get current collateral ratio
     * @return Ratio (1e18 = 100%)
     */
    function getCollateralRatio() external view returns (uint256) {
        uint256 outstandingZkn = zknToken.totalSupply();
        if (outstandingZkn == 0) return type(uint256).max;
        
        return (totalCollateral * 1e18 * 1e12) / outstandingZkn;
    }

    /**
     * @notice Get available collateral for withdrawal
     * @return Available USDC amount
     */
    function getAvailableCollateral() external view returns (uint256) {
        uint256 outstandingZkn = zknToken.totalSupply();
        uint256 requiredCollateral = (outstandingZkn * minCollateralRatio) / (1e18 * 1e12);
        return totalCollateral > requiredCollateral 
            ? totalCollateral - requiredCollateral 
            : 0;
    }
}
```

### 2.3 Uniswap v4 Hook Contract

**File:** `contracts/UniswapHook.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";

/**
 * @title ZakoKenHook
 * @notice Uniswap v4 hook for ZKK-USDC stable pair
 * @dev Implements dynamic fees and arbitrage detection
 */
contract ZakoKenHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // ============ State Variables ============

    /// @notice Fixed exchange contract address for price comparison
    address public immutable fixedExchange;

    /// @notice Base fee (0.05% = 500)
    uint24 public constant BASE_FEE = 500;

    /// @notice Maximum fee (2% = 20000)
    uint24 public constant MAX_FEE = 20000;

    /// @notice Minimum fee (0.01% = 100)
    uint24 public constant MIN_FEE = 100;

    /// @notice Volatility measurement window
    uint256 public constant VOLATILITY_WINDOW = 10 minutes;

    /// @notice Recent prices for volatility calculation
    struct PriceSnapshot {
        uint256 price;
        uint256 timestamp;
    }
    
    PriceSnapshot[] public priceHistory;

    // ============ Events ============

    event DynamicFeeUpdated(PoolId indexed poolId, uint24 newFee);
    event ArbitrageOpportunity(PoolId indexed poolId, int256 priceDeviation);
    event PriceRecorded(uint256 price, uint256 timestamp);

    // ============ Constructor ============

    constructor(
        IPoolManager _poolManager,
        address _fixedExchange
    ) BaseHook(_poolManager) {
        fixedExchange = _fixedExchange;
    }

    // ============ Hook Implementations ============

    /**
     * @notice Get hook permissions
     */
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /**
     * @notice Hook called after pool initialization
     */
    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160,
        int24,
        bytes calldata
    ) external override returns (bytes4) {
        // Initialize price history
        priceHistory.push(PriceSnapshot({
            price: 1e18, // Start at 1:1
            timestamp: block.timestamp
        }));

        return BaseHook.afterInitialize.selector;
    }

    /**
     * @notice Hook called before swap
     * @dev Calculates and applies dynamic fee
     */
    function beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        // Calculate current price (simplified)
        uint256 currentPrice = getCurrentPrice(key);

        // Record price for volatility calculation
        recordPrice(currentPrice);

        // Calculate volatility
        uint256 volatility = calculateVolatility();

        // Calculate price deviation from 1:1 peg
        int256 deviation = int256(currentPrice) - int256(1e18);
        int256 deviationPct = (deviation * 100) / int256(1e18);

        // Calculate dynamic fee
        uint24 dynamicFee = calculateDynamicFee(volatility, deviationPct);

        // Check for arbitrage opportunity
        if (abs(deviationPct) > 1) { // >1% deviation
            emit ArbitrageOpportunity(key.toId(), deviationPct);
        }

        emit DynamicFeeUpdated(key.toId(), dynamicFee);

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            dynamicFee
        );
    }

    /**
     * @notice Hook called after swap
     * @dev Records swap data for analysis
     */
    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4, int128) {
        // Record post-swap price
        uint256 newPrice = getCurrentPrice(key);
        recordPrice(newPrice);

        return (BaseHook.afterSwap.selector, 0);
    }

    // ============ Internal Functions ============

    /**
     * @notice Calculate dynamic fee based on market conditions
     * @param volatility Market volatility
     * @param deviationPct Price deviation percentage
     * @return Dynamic fee (basis points)
     */
    function calculateDynamicFee(
        uint256 volatility,
        int256 deviationPct
    ) internal pure returns (uint24) {
        // Base fee
        uint256 fee = BASE_FEE;

        // Add volatility component (0-500 bps)
        fee += (volatility * 500) / 1e18;

        // Add deviation component (0-1000 bps)
        uint256 absDeviation = abs(deviationPct);
        fee += (absDeviation * 100); // 1% deviation = 100 bps

        // Clamp to min/max
        if (fee < MIN_FEE) fee = MIN_FEE;
        if (fee > MAX_FEE) fee = MAX_FEE;

        return uint24(fee);
    }

    /**
     * @notice Calculate market volatility
     * @return Volatility measure (1e18 = 100%)
     */
    function calculateVolatility() internal view returns (uint256) {
        if (priceHistory.length < 2) return 0;

        uint256 cutoff = block.timestamp - VOLATILITY_WINDOW;
        uint256 sumSquaredDiff = 0;
        uint256 count = 0;
        uint256 meanPrice = 1e18; // Assume mean is 1:1

        for (uint256 i = priceHistory.length; i > 0; i--) {
            if (priceHistory[i - 1].timestamp < cutoff) break;
            
            int256 diff = int256(priceHistory[i - 1].price) - int256(meanPrice);
            sumSquaredDiff += uint256(diff * diff);
            count++;
        }

        if (count == 0) return 0;

        // Standard deviation
        uint256 variance = sumSquaredDiff / count;
        return sqrt(variance);
    }

    /**
     * @notice Record price snapshot
     * @param price Current price
     */
    function recordPrice(uint256 price) internal {
        priceHistory.push(PriceSnapshot({
            price: price,
            timestamp: block.timestamp
        }));

        // Keep only recent history (last 100 snapshots)
        if (priceHistory.length > 100) {
            // Shift array (remove oldest)
            for (uint256 i = 0; i < priceHistory.length - 1; i++) {
                priceHistory[i] = priceHistory[i + 1];
            }
            priceHistory.pop();
        }

        emit PriceRecorded(price, block.timestamp);
    }

    /**
     * @notice Get current pool price
     * @param key Pool key
     * @return Current price (1e18 = 1:1)
     */
    function getCurrentPrice(PoolKey calldata key) internal view returns (uint256) {
        // Get pool slot0 data
        (uint160 sqrtPriceX96,,) = poolManager.getSlot0(key.toId());
        
        // Convert sqrtPriceX96 to price
        // price = (sqrtPriceX96 / 2^96)^2
        uint256 priceX96 = uint256(sqrtPriceX96);
        uint256 price = (priceX96 * priceX96 * 1e18) / (2**192);
        
        return price;
    }

    // ============ Helper Functions ============

    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
```

### 2.4 Build and Test Contracts

```bash
# Compile contracts
pnpm hardhat compile

# Run tests
pnpm hardhat test

# Run tests with gas reports
REPORT_GAS=true pnpm hardhat test

# Run specific test
pnpm hardhat test test/ZKK.test.ts

# Coverage
pnpm hardhat coverage

# Check contract size
pnpm hardhat size-contracts
```

---

## 3. Frontend Development

### 3.1 Project Setup

```bash
cd frontend

# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build
```

### 3.2 Key Components

**File:** `frontend/src/components/WalletConnect.tsx`

```typescript
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useNetwork } from 'wagmi';

export function WalletConnect() {
  const { address, isConnected } = useAccount();
  const { chain } = useNetwork();

  return (
    <div className="flex items-center gap-4">
      <ConnectButton />
      {isConnected && (
        <div className="text-sm">
          <p>Connected: {address?.slice(0, 6)}...{address?.slice(-4)}</p>
          <p>Network: {chain?.name}</p>
        </div>
      )}
    </div>
  );
}
```

**File:** `frontend/src/components/MintSimulator.tsx`

```typescript
import { useState } from 'react';
import { useContractWrite, usePrepareContractWrite } from 'wagmi';
import { parseEther, keccak256, toBytes } from 'viem';
import { ZKK_ABI, ZKK_ADDRESS } from '../utils/contracts';

export function MintSimulator() {
  const [amount, setAmount] = useState('100');
  const [loading, setLoading] = useState(false);

  // Generate transaction hash (simulated)
  const txHash = keccak256(toBytes(`tx-${Date.now()}`));
  const projectId = keccak256(toBytes('zakoken-demo'));

  // Prepare contract write
  const { config } = usePrepareContractWrite({
    address: ZKK_ADDRESS,
    abi: ZKK_ABI,
    functionName: 'mintWithCompose',
    args: [
      address, // to
      parseEther(amount), // amount
      txHash, // txHash
      projectId // projectId
    ],
  });

  const { write } = useContractWrite(config);

  const handleMint = async () => {
    if (!write) return;
    
    setLoading(true);
    try {
      await write();
      // Wait for transaction confirmation
      // Then update UI
    } catch (error) {
      console.error('Mint failed:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card p-6">
      <h2 className="text-2xl font-bold mb-4">Simulate Off-Chain Transaction</h2>
      
      <div className="space-y-4">
        <div>
          <label className="label">
            Amount to Mint
          </label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="input"
            placeholder="100"
          />
        </div>

        <button
          onClick={handleMint}
          disabled={loading || !write}
          className="btn btn-primary w-full"
        >
          {loading ? 'Minting...' : 'Mint ZKK Tokens'}
        </button>

        <div className="text-sm text-gray-600">
          <p>This simulates an off-chain transaction and mints ZKK tokens</p>
          <p>Transaction hash: {txHash.slice(0, 10)}...</p>
        </div>
      </div>
    </div>
  );
}
```

**File:** `frontend/src/components/SwapInterface.tsx`

```typescript
import { useState } from 'react';
import { useContractWrite } from 'wagmi';
import { parseEther, parseUnits } from 'viem';
import { FIXED_EXCHANGE_ABI, FIXED_EXCHANGE_ADDRESS } from '../utils/contracts';

export function SwapInterface() {
  const [activePool, setActivePool] = useState<'fixed' | 'uniswap'>('fixed');
  const [zknAmount, setZknAmount] = useState('');

  // Fixed pool redemption
  const { write: redeemFixed } = useContractWrite({
    address: FIXED_EXCHANGE_ADDRESS,
    abi: FIXED_EXCHANGE_ABI,
    functionName: 'redeem',
  });

  // Uniswap pool swap
  const { write: swapUniswap } = useContractWrite({
    address: UNISWAP_ROUTER_ADDRESS,
    abi: UNISWAP_ROUTER_ABI,
    functionName: 'swap',
  });

  const handleSwap = async () => {
    const amount = parseEther(zknAmount);
    
    if (activePool === 'fixed') {
      await redeemFixed({ args: [amount] });
    } else {
      // Uniswap swap logic
      await swapUniswap({ args: [/* swap params */] });
    }
  };

  return (
    <div className="grid grid-cols-2 gap-4">
      {/* Fixed Pool */}
      <div 
        className={`card p-6 cursor-pointer ${activePool === 'fixed' ? 'ring-2 ring-blue-500' : ''}`}
        onClick={() => setActivePool('fixed')}
      >
        <h3 className="text-xl font-bold mb-2">Fixed Pool</h3>
        <p className="text-gray-600 mb-4">Guaranteed 1:1 USDC</p>
        
        <div className="space-y-2">
          <div className="flex justify-between">
            <span>Exchange Rate:</span>
            <span className="font-mono">1.000 USDC</span>
          </div>
          <div className="flex justify-between">
            <span>Fee:</span>
            <span className="font-mono">0%</span>
          </div>
        </div>
      </div>

      {/* Uniswap Pool */}
      <div 
        className={`card p-6 cursor-pointer ${activePool === 'uniswap' ? 'ring-2 ring-blue-500' : ''}`}
        onClick={() => setActivePool('uniswap')}
      >
        <h3 className="text-xl font-bold mb-2">Uniswap v4 Pool</h3>
        <p className="text-gray-600 mb-4">Market Rate</p>
        
        <div className="space-y-2">
          <div className="flex justify-between">
            <span>Exchange Rate:</span>
            <span className="font-mono">0.998 USDC</span>
          </div>
          <div className="flex justify-between">
            <span>Fee:</span>
            <span className="font-mono">0.05%</span>
          </div>
        </div>
      </div>

      {/* Swap Input */}
      <div className="col-span-2 card p-6">
        <input
          type="number"
          value={zknAmount}
          onChange={(e) => setZknAmount(e.target.value)}
          placeholder="Amount of ZKK"
          className="input w-full mb-4"
        />

        <button
          onClick={handleSwap}
          className="btn btn-primary w-full"
        >
          Swap on {activePool === 'fixed' ? 'Fixed' : 'Uniswap'} Pool
        </button>
      </div>
    </div>
  );
}
```

---

## 4. Testing Guide

### 4.1 Smart Contract Tests

**File:** `test/ZKK.test.ts`

```typescript
import { expect } from "chai";
import { ethers } from "hardhat";
import { ZKK } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("ZKK Token", function () {
  let zkk: ZKK;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let endpoint: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, endpoint] = await ethers.getSigners();

    const ZKK = await ethers.getContractFactory("ZKK");
    zkk = await ZKK.deploy(
      "ZakoKen",
      "ZKK",
      endpoint.address,
      owner.address
    );
    await zkk.waitForDeployment();
  });

  describe("Minting with Compose", function () {
    it("Should mint tokens with compose message", async function () {
      const amount = ethers.parseEther("100");
      const txHash = ethers.keccak256(ethers.toUtf8Bytes("test-tx"));
      const projectId = ethers.keccak256(ethers.toUtf8Bytes("test-project"));

      await zkk.mintWithCompose(user1.address, amount, txHash, projectId);

      expect(await zkk.balanceOf(user1.address)).to.equal(amount);
    });

    it("Should apply greed model to reduce repeat mints", async function () {
      const baseAmount = ethers.parseEther("100");
      
      // First mint
      await zkk.mintWithCompose(
        user1.address,
        baseAmount,
        ethers.keccak256(ethers.toUtf8Bytes("tx1")),
        ethers.keccak256(ethers.toUtf8Bytes("project"))
      );
      const balance1 = await zkk.balanceOf(user1.address);

      // Second mint should be reduced due to concentration
      await zkk.mintWithCompose(
        user1.address,
        baseAmount,
        ethers.keccak256(ethers.toUtf8Bytes("tx2")),
        ethers.keccak256(ethers.toUtf8Bytes("project"))
      );
      const balance2 = await zkk.balanceOf(user1.address);

      expect(balance2).to.be.lt(balance1 * 2n);
    });
  });
});
```

---

## 5. Integration Points

### 5.1 LayerZero Configuration

```typescript
// Set trusted remotes for cross-chain
const setPeer = await zknOFT.setPeer(
  destinationEid, // e.g., 40231 for Sepolia
  addressToBytes32(destinationZknAddress)
);

// Configure DVNs
const setConfig = await zknOFT.setConfig(
  destinationEid,
  SEND_LIB,
  CONFIG_TYPE_ULN,
  encodedConfig // Contains DVN addresses, confirmations, etc.
);
```

### 5.2 Uniswap v4 Pool Creation

```solidity
// Create pool with hook
PoolKey memory key = PoolKey({
    currency0: Currency.wrap(address(zkn)),
    currency1: Currency.wrap(address(usdc)),
    fee: 0, // Dynamic fee handled by hook
    tickSpacing: 60,
    hooks: IHooks(address(zakoKenHook))
});

poolManager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
```

---

## 6. Common Issues & Solutions

### 6.1 LayerZero Issues

**Issue:** "LzApp: invalid endpoint caller"
- **Solution:** Ensure only LayerZero endpoint calls `_lzReceive()`

**Issue:** "Insufficient gas for compose"
- **Solution:** Increase `composeMsgGasLimit` in send options

### 6.2 Uniswap v4 Issues

**Issue:** "Hook address validation failed"
- **Solution:** Hook address must have correct prefix based on permissions

**Issue:** "Invalid tick spacing"
- **Solution:** Use tick spacing compatible with fee tier

### 6.3 Frontend Issues

**Issue:** Transaction fails with "User rejected"
- **Solution:** Check wallet has sufficient ETH for gas

**Issue:** Contract read fails
- **Solution:** Verify RPC URL and contract address

---

**Document Version:** 1.0  
**Last Updated:** November 22, 2025  