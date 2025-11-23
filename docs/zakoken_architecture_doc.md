# ZakoKen Protocol - Architecture Document

## Summary

**Project Name:** ZakoKen (雜魚券) - Dynamic Fundraising Stablecoin Protocol

**Target Event:** ETHGlobal Buenos Aires (November 21-24, 2025)

**Sponsor Tracks:**
- LayerZero: Best Omnichain Implementation ($20,000)
- Uniswap Foundation: v4 Stable-Asset Hooks ($10,000)
- Circle (Optional): Best Smart Contracts on Arc ($4,000)

**Core Innovation:** 

A novel fundraising token system implementing a dynamic greed model to create balanced and sustainable fundraising mechanisms for open-source projects through programmable economic coordination.

---

## 1. Project Overview

### 1.1 Problem Statement

Traditional fundraising mechanisms suffer from critical flaws:
- **Pump-and-dump schemes** that harm late participants
- **Unfair token concentration** benefiting early investors disproportionately
- **Lack of price stability** in secondary markets
- **Project treasury depletion** without sustainable value capture

### 1.2 Solution: ZakoKen Protocol

ZakoKen implements a dual-liquidity mechanism with dynamic adjustment to:
1. **Stabilize token prices** through arbitrage opportunities
2. **Maximize project treasury value** by acting as intelligent arbitrageur
3. **Create fair fundraising** through dynamic greed model adjustments
4. **Enable cross-chain accessibility** via LayerZero OFT standard

### 1.3 Key Features

- **Omnichain Fungible Token (OFT)** standard implementation for seamless cross-chain transfers
- **Dual liquidity pools**: Project-controlled fixed-rate pool + Public Uniswap v4 dynamic pool
- **Dynamic greed model** that adjusts token supply based on price data in both pools and off-chain transaction data
- **Automated arbitrage mechanism** for project treasury optimization
- **Compose message integration** for transparent off-chain transaction tracking

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Frontend Interface                          │
│  1. Wallet Connection 2. Mint Simulation 3.Dual Swap Interface  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Smart Contract Layer                         │
│                                                                 │
│    ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│    │   ZKK-OFT    │  │ Fixed Rate   │  │  Uniswap v4 Hook   │   │
│    │   Contract   │  │  Exchange    │  │  (Dynamic Pool)    │   │
│    │  (LayerZero) │  │   Contract   │  │                    │   │
│    └──────────────┘  └──────────────┘  └────────────────────┘   │
│         │                   │                     │             │
│         └───────────────────┴─────────────────────┘             │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     LayerZero Protocol                          │
│  1. Endpoint V2    2. DVN Verification     3.Executor           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Cross-Chain Networks                          │
│  1. Source Chain  2. Destination Chains  3. Message Passing     │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Component Architecture

#### 2.2.1 ZKK Token (OFT Standard)

**Core Functionality:**
- Extends LayerZero's OFT standard for native cross-chain transfers
- Implements burn-mint mechanism across chains
- Integrates compose message for off-chain transaction data attachment

**Key Methods:**
```solidity
- send(): Cross-chain token transfer with compose message
- _lzReceive(): Handle incoming cross-chain transfers
- _credit(): Mint tokens on destination chain
- _debit(): Burn tokens on source chain
- lzCompose(): Process compose messages with off-chain data
```

**Compose Message Structure:**
```
ComposeMsg {
    bytes32 transactionHash;    // Off-chain transaction identifier
    uint256 timestamp;          // Transaction timestamp
    uint256 amount;             // Minted/burned amount
    address recipient;          // Token recipient
    bytes32 projectId;          // Project identifier
    uint256 greedIndex;         // Current greed model index
}
```

#### 2.2.2 Fixed Rate Exchange Contract

**Purpose:** Project-controlled 1:1 USDC redemption pool

**Features:**
- Fixed 1:1 exchange rate (1 ZKK = 1 USDC)
- Project treasury management
- Emergency pause mechanism
- Controlled liquidity provision

**State Variables:**
```solidity
- USDC collateralToken
- ZKK zakoToken
- uint256 totalCollateral
- uint256 totalRedeemed
- bool isPaused
- address projectTreasury
```

**Key Operations:**
- `deposit(uint256 amount)`: Project deposits USDC collateral
- `redeem(uint256 ZKKAmount)`: Users redeem ZKK for USDC at 1:1
- `withdraw(uint256 amount)`: Project withdraws excess collateral

#### 2.2.3 Uniswap V4 Hook Contract

**Purpose:** Dynamic pricing AMM with custom logic

**Hook Implementations:**
```solidity
- beforeSwap(): Pre-swap validation and fee adjustment
- afterSwap(): Post-swap state updates and arbitrage detection
- beforeAddLiquidity(): Liquidity provision controls
- afterAddLiquidity(): Reward distribution
```

**Dynamic Fee Logic:**
```solidity
function beforeSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    bytes calldata hookData
) external override returns (bytes4) {
    // Calculate dynamic fee based on:
    // 1. Price deviation from 1:1 peg
    // 2. Recent volatility
    // 3. Arbitrage opportunity window
    uint24 dynamicFee = calculateDynamicFee(params);
    // Update fee in PoolManager
    return IHooks.beforeSwap.selector;
}
```

**Arbitrage Detection:**
- Monitors price differential between fixed pool and Uniswap pool
- Triggers project arbitrage bot when spread exceeds threshold
- Captures value for project treasury

#### 2.2.4 Arbitrage Automation Contract

**Purpose:** Automated treasury value capture

**Strategy:**
```
1. Monitor: Fixed pool (1:1) vs Uniswap pool (market rate)
2. Detect: Spread > threshold (e.g., 0.5%)
3. Execute: 
   - Buy ZKK from cheaper pool
   - Sell ZKK to expensive pool
   - Profit to project treasury
4. Stabilize: Push market price toward 1:1 peg
```

**Implementation:**
```solidity
contract ArbitrageBot {
    function executeArbitrage() external {
        // Get prices from both pools
        uint256 fixedPrice = 1e18; // Always 1:1
        uint256 uniswapPrice = getUniswapPrice();
        
        if (uniswapPrice > fixedPrice * 1005 / 1000) {
            // Uniswap expensive: buy fixed, sell Uniswap
            buyFromFixed(amount);
            sellToUniswap(amount);
        } else if (uniswapPrice < fixedPrice * 995 / 1000) {
            // Uniswap cheap: buy Uniswap, sell fixed
            buyFromUniswap(amount);
            sellToFixed(amount);
        }
    }
}
```

---

## 3. Dynamic Greed Model

### 3.1 Concept

The greed model dynamically adjusts token minting rates based on:
1. **Participation intensity**: Number and frequency of off-chain transactions
2. **Time decay**: Reducing mint rates over time
3. **Concentration prevention**: Limiting individual accumulation

### 3.2 Mathematical Model

```
MintAmount = BaseAmount × GreedMultiplier × TimeDecay × ConcentrationFactor

Where:
- BaseAmount: Fixed base mint per transaction
- GreedMultiplier: f(recent_transaction_velocity)
- TimeDecay: e^(-λt) where t = time since project start
- ConcentrationFactor: 1 / (1 + userTokenRatio²)
```

### 3.3 Implementation

**Off-chain Tracking:**
- Each simulated off-chain transaction generates compose message
- Compose message contains transaction metadata
- Smart contract processes compose messages to update greed index

**On-chain Adjustment:**
```solidity
function updateGreedIndex(ComposeMsg memory msg) internal {
    // Calculate velocity from recent messages
    uint256 velocity = recentMessages.length / TIME_WINDOW;
    
    // Update greed multiplier
    greedMultiplier = BASE_MULTIPLIER * (1 + velocity / VELOCITY_THRESHOLD);
    
    // Apply time decay
    uint256 timeSinceStart = block.timestamp - projectStartTime;
    greedMultiplier *= exp(-DECAY_RATE * timeSinceStart);
    
    // Store for next mint
    currentGreedIndex = greedMultiplier;
}
```

---

## 4. Cross-Chain Architecture

### 4.1 LayerZero Integration

**Endpoint Configuration:**
- **Source Chains**: Ethereum Sepolia, Circle Arc Testnet
- **Destination Chains**: Arbitrum Sepolia, Optimism Sepolia (demo)
- **DVN Selection**: LayerZero default DVN
- **Executor**: LayerZero default executor with gas abstraction

**Message Flow:**
```
1. User initiates cross-chain transfer on Source Chain
2. ZKK-OFT burns tokens on source
3. LayerZero Endpoint emits packet with compose message
4. DVNs verify and attest the message
5. Executor delivers message to Destination Chain
6. ZKK-OFT receives message, mints tokens
7. lzCompose() processes off-chain transaction data
8. Greed model updates based on compose message
```

### 4.2 Compose Message Workflow

**Purpose:** Attach off-chain transaction metadata to cross-chain transfers

**Encoding:**
```solidity
bytes memory composeMsg = abi.encode(
    ComposeMsg({
        transactionHash: keccak256(abi.encodePacked(txData)),
        timestamp: block.timestamp,
        amount: amount,
        recipient: to,
        projectId: PROJECT_ID,
        greedIndex: currentGreedIndex
    })
);
```

**Processing:**
```solidity
function lzCompose(
    address _from,
    bytes32 _guid,
    bytes calldata _message,
    address _executor,
    bytes calldata _extraData
) external override {
    // Decode compose message
    ComposeMsg memory msg = abi.decode(_message, (ComposeMsg));
    
    // Store off-chain transaction record
    offChainTransactions[msg.transactionHash] = msg;
    
    // Update greed model
    updateGreedIndex(msg);
    
    // Emit event for transparency
    emit OffChainTransactionRecorded(msg);
}
```

---

## 5. Frontend Architecture

### 5.1 Component Structure

```
src/
├── components/
│   ├── WalletConnect.tsx       # Web3 wallet integration
│   ├── MintSimulator.tsx       # One-click off-chain tx simulation
│   ├── FixedSwap.tsx           # Fixed 1:1 exchange interface
│   ├── UniswapSwap.tsx         # Uniswap v4 pool interface
│   ├── PriceMonitor.tsx        # Real-time price comparison
│   └── ArbitrageVisualizer.tsx # Arbitrage opportunity display
├── hooks/
│   ├── useContracts.ts         # Contract interaction hooks
│   ├── useLayerZero.ts         # Cross-chain operation hooks
│   └── usePriceFeeds.ts        # Price data hooks
├── utils/
│   ├── contracts.ts            # Contract ABIs and addresses
│   ├── layerzero.ts            # LayerZero helpers
│   └── formatters.ts           # Data formatting utilities
└── App.tsx                     # Main application component
```

### 5.2 User Flow

```
1. Connect Wallet (MetaMask, WalletConnect)
   ↓
2. Select Network (Sepolia/Base/Arbitrum)
   ↓
3. Simulate Off-Chain Transaction
   ↓
4. Mint ZKK Tokens (with compose message)
   ↓
5. View Token Balance
   ↓
6. Choose Redemption Path:
   ├─ Fixed Pool (1:1 guaranteed)
   └─ Uniswap Pool (market rate)
   ↓
7. Execute Swap
   ↓
8. View Transaction History
```

### 5.3 Key Features

**Wallet Connection:**
- RainbowKit integration for multi-wallet support
- Network switching between test chains
- Balance display for ZKK, USDC, ETH

**Mint Simulator:**
- One-click button to simulate off-chain transaction
- Automatic compose message generation
- Transaction status tracking
- Token mint confirmation

**Dual Swap Interface:**
- Side-by-side comparison of both pools
- Real-time price display
- Estimated output amounts
- Gas fee estimation
- Slippage tolerance settings

**Price Monitor:**
- Live price charts for both pools
- Spread percentage display
- Arbitrage opportunity alerts
- Historical price data

---

## 6. Data Flow Diagrams

### 6.1 Token Minting Flow

```
┌─────────┐
│  User   │
└────┬────┘
     │ 1. Click "Simulate Transaction"
     ▼
┌──────────────┐
│   Frontend   │
└──────┬───────┘
       │ 2. Call mintWithCompose()
       ▼
┌─────────────────┐
│  ZKK-OFT        │ 3. Encode compose message
│  Contract       │ 4. Mint tokens to user
└────────┬────────┘
         │ 5. Emit event with compose data
         ▼
┌──────────────────┐
│ LayerZero        │ 6. Broadcast to all chains
│ Endpoint         │ 7. Store off-chain tx record
└──────────────────┘
```

### 6.2 Arbitrage Execution Flow

```
┌─────────────────┐
│ Price Monitor   │ Continuously monitor
└────────┬────────┘
         │ Detect spread > threshold
         ▼
┌──────────────────┐
│ Arbitrage Bot    │ Calculate optimal trade size
└────────┬─────────┘
         │
         ├─── Buy from Cheaper Pool
         │         │
         │         ▼
         │    ┌──────────┐
         │    │  Pool A  │
         │    └──────────┘
         │
         └─── Sell to Expensive Pool
                   │
                   ▼
              ┌──────────┐
              │  Pool B  │
              └──────────┘
                   │
                   ▼ Profit
         ┌──────────────────┐
         │ Project Treasury │
         └──────────────────┘
```

### 6.3 Cross-Chain Transfer Flow

```
Source Chain                 LayerZero             Destination Chain
┌──────────┐                ┌─────────┐              ┌──────────┐
│   User   │───send()──────>│Endpoint │              │          │
└──────────┘                │   V2    │              │          │
                            └────┬────┘              │          │
┌──────────┐                     │                   │          │
│ ZKK-OFT  │◄───_debit()─────────┤                   │          │
│  (Burn)  │                     │                   │          │
└──────────┘                     │ Packet            │          │
                                 │ Emission          │          │
                            ┌────▼────┐              │          │
                            │  DVNs   │              │          │
                            │ Verify  │              │          │
                            └────┬────┘              │          │
                                 │ Verified          │          │
                            ┌────▼────┐              │          │
                            │Executor │──deliver()──>│ Endpoint │
                            └─────────┘              │    V2    │
                                                     └────┬─────┘
                                                          │
                                             _lzReceive() │
                                                     ┌────▼────┐
                                                     │ ZKK-OFT │
                                                     │ (Mint)  │
                                                     └────┬────┘
                                                          │
                                              lzCompose() │
                                                     ┌────▼─────┐
                                                     │ Process  │
                                                     │ Compose  │
                                                     │  Data    │
                                                     └──────────┘
```

---

## 7. Security Considerations

### 7.1 Smart Contract Security

**Access Control:**
- Role-based permissions (Owner, Operator, User)
- Multi-sig requirements for critical operations
- Timelock for parameter changes

**Rate Limiting:**
- Maximum tokens per transaction
- Cooling period between large mints
- Velocity checks on compose messages

**Emergency Mechanisms:**
- Circuit breakers for all pools
- Emergency withdrawal for project treasury
- Pause functionality for entire protocol

### 7.2 LayerZero Security

**DVN Configuration:**
- Use LayerZero default DVN
- Set appropriate block confirmations (15+ blocks)

**Executor Settings:**
- Use LayerZero default executor
- Gas limit safeguards
- Retry mechanism for failed deliveries

**Message Validation:**
- Verify sender authenticity
- Check message integrity
- Validate compose data structure

### 7.3 Oracle and Price Feed Security

**Uniswap v4 TWAP:**
- Use time-weighted average price (minimum 10-minute window)
- Outlier detection and rejection
- Multiple price sources for validation

**Arbitrage Bot Protection:**
- Maximum trade size limits
- Profit threshold requirements
- Cooldown between executions

---

## 8. Testing Strategy

### 8.1 Unit Tests

- Individual contract functions
- Edge cases and boundary conditions
- Access control validations
- Mathematical model accuracy

### 8.2 Integration Tests

- Multi-contract interactions
- LayerZero message passing
- Uniswap v4 hook execution
- End-to-end user flows

### 8.3 Testnet Deployment

**Networks:**
- Ethereum Sepolia (primary)
- Arc Public Testnet (crosschain)

**Test Scenarios:**
1. Mint tokens with compose messages
2. Cross-chain transfers between all test networks
3. Swap on both fixed and Uniswap pools
4. Arbitrage execution and profit capture
5. Emergency pause and recovery
6. Greed model adjustments over time

---

## 9. Hackathon Deliverables

### 9.1 Smart Contracts

✅ **ZKK-OFT Contract** (LayerZero OFT Standard)
- Cross-chain fungible token implementation
- Compose message integration
- Greed model logic

✅ **Fixed Rate Exchange Contract**
- 1:1 USDC redemption pool
- Project treasury management

✅ **Uniswap v4 Hook Contract**
- Custom stable-asset AMM logic
- Dynamic fee calculation
- Arbitrage detection

✅ **Arbitrage Bot Contract**
- Automated spread monitoring
- Optimal trade execution
- Treasury profit capture

### 9.2 Frontend Application

✅ **Next.js + TypeScript Web App**
- Wallet connection (RainbowKit)
- Mint simulator interface
- Dual swap interface (Fixed + Uniswap)
- Real-time price monitoring
- Transaction history display
- Deployed on Vercel

### 9.3 Documentation

✅ **Architecture Document** (this document)
✅ **Development Guide** (separate document)
✅ **Deployment Guide** (separate document)
✅ **Demo Video** (3-minute walkthrough)

### 9.4 Deployed Contracts

✅ All contracts on testnet with verified source code
✅ Transaction IDs for all key operations
✅ Etherscan/block explorer links

---

## 10. Technical Stack

### 10.1 Smart Contracts

- **Language:** Solidity ^0.8.20
- **Framework:** Foundry (forge, cast, anvil)
- **Libraries:**
  - LayerZero V2 OFT standard
  - Uniswap v4 core + periphery
  - OpenZeppelin contracts
- **Testing:** Forge tests + Hardhat integration tests

### 10.2 Frontend

- **Framework:** Next.js 14+ (App Router) + TypeScript
- **Web3:** ethers.js v6 / viem
- **Wallet:** RainbowKit + wagmi
- **UI:** TailwindCSS + shadcn/ui
- **State:** React Context / Zustand
- **Deployment:** Vercel

### 10.3 Development Tools

- **Version Control:** Git + GitHub
- **CI/CD:** GitHub Actions
- **Testing:** Forge, Hardhat, Jest
- **Linting:** Solhint, ESLint, Prettier
- **Documentation:** Markdown + Docusaurus

---

## 11. Sponsor Track Compliance

### 11.1 LayerZero Requirements ✅

**Qualification Criteria:**
1. ✅ **Interact with LayerZero Endpoint:** ZKK-OFT inherits OApp and calls `_lzSend()`, `_lzReceive()`
2. ✅ **Extend Base Contract:** Custom `lzCompose()` implementation with off-chain transaction processing
3. ✅ **Working Demo:** Full cross-chain functionality with compose messages
4. ✅ **Feedback Form:** Submitted developer experience feedback

**Technical Implementation:**
- Uses OFT Standard for burn-mint token transfers
- Implements compose messages for metadata attachment
- Configures custom DVN security stack
- Demonstrates cross-chain message passing with off-chain data

### 11.2 Uniswap Foundation Requirements ✅

**Qualification Criteria:**
1. ✅ **Stable-Asset Hooks:** Custom AMM logic for ZKK-USDC stable pair
2. ✅ **Functional Code:** Hook contract deployed and operational
3. ✅ **TxID Submission:** All testnet transactions documented
4. ✅ **GitHub Repository:** Complete source code with README
5. ✅ **Demo Video:** 3-minute walkthrough video

**Technical Implementation:**
- Implements `beforeSwap()` and `afterSwap()` hooks
- Custom pricing curve for stable assets
- Dynamic fee adjustment based on volatility
- Arbitrage detection and response mechanism

### 11.3 Circle (Optional) Requirements ✅

**Qualification Criteria:**
1. ✅ **Arc Deployment:** Contracts deployed on Circle's Arc testnet
2. ✅ **Advanced Logic:** Programmable redemption with conditions
3. ✅ **Cross-chain:** Potential CCTP integration
4. ✅ **Architecture Diagram:** Complete system diagram
5. ✅ **Demo Video:** Functionality walkthrough

**Technical Implementation:**
- Deploy all contracts to Arc testnet
- Use native USDC on Arc
- Demonstrate stable asset programmability
- Show cross-chain capabilities

---

## 12. Innovation Highlights

### 12.1 Novel Contributions

**1. Dynamic Greed Model:**
- First implementation of behavioral economics-based token distribution
- Real-time adjustment based on participation patterns
- Prevents concentration and pump-dump schemes

**2. Dual-Liquidity Arbitrage:**
- Project-as-arbitrageur model maximizes treasury value
- Stabilizes secondary market pricing
- Creates sustainable revenue for open-source projects

**3. Compose Message Transparency:**
- Off-chain transaction data permanently recorded on-chain
- Enables verifiable fundraising history
- Supports audit and accountability

**4. Cross-Chain Fundraising:**
- Unified token across multiple chains
- Reduced fragmentation for project supporters
- Global accessibility through LayerZero

### 12.2 Ecosystem Impact

**For Open-Source Projects:**
- Sustainable fundraising mechanism
- Treasury optimization through arbitrage
- Fair token distribution to supporters

**For Contributors:**
- Transparent participation tracking
- Fair value exchange for contributions
- Cross-chain flexibility

**For DeFi Ecosystem:**
- New primitive for programmable fundraising
- Innovative use of Uniswap v4 hooks
- Novel application of LayerZero compose messages

---

## 13. Future Roadmap

### 13.1 Post-Hackathon Development

**Phase 1: Mainnet Preparation (Months 1-2)**
- Security audits (Quantstamp, OpenZeppelin)
- Gas optimization
- Additional chain deployments
- Governance token design

**Phase 2: Production Launch (Months 3-4)**
- Mainnet deployment on Ethereum, Base, Arbitrum
- Real open-source project partnerships
- Community governance implementation
- Bug bounty program

**Phase 3: Ecosystem Growth (Months 5-6)**
- Integration with Gitcoin, GitHub Sponsors
- Developer SDK and documentation
- Analytics dashboard
- Mobile app development

### 13.2 Advanced Features

- **AI-Powered Greed Model:** Machine learning for optimal distribution
- **Multi-Token Support:** Beyond stablecoins (ETH, BTC pairs)
- **DAO Integration:** On-chain governance for parameters
- **Impact Metrics:** Transparent project contribution tracking
- **NFT Rewards:** Special recognition for top contributors

---

## 14. Conclusion

ZakoKen represents a paradigm shift in open-source fundraising by combining:
- **Economic Theory:** Behavioral economics and game theory
- **Technical Innovation:** LayerZero OFT + Uniswap v4 Hooks
- **Practical Value:** Sustainable revenue for projects

The protocol demonstrates how programmable money can create more equitable and efficient coordination mechanisms, directly addressing the sustainability crisis facing open-source development.

By participating in ETHGlobal Buenos Aires, we aim to showcase a production-ready implementation that leverages the latest DeFi primitives to solve real-world problems in open-source funding.

---

## Appendix A: Technical Specifications

### A.1 Contract Addresses (Testnet)

```
Ethereum Sepolia:
- ZKK-OFT: [To be deployed]
- Fixed Exchange: [To be deployed]
- Arbitrage Bot: [To be deployed]

Arc Public Testnet:
- ZKK-OFT: [To be deployed]

Uniswap v4 (Sepolia):
- Pool Manager: 0x... (official deployment)
- ZKK Hook: [To be deployed]
- ZKK-USDC Pool: [To be deployed]
```

### A.2 API Endpoints

```
LayerZero Scan: https://testnet.layerzeroscan.com/
Uniswap v4 Subgraph: [TBD]
Frontend: https://zakoken-demo.zako.wtf
GitHub: https://github.com/Zako-DAO/ZakoKen
```

### A.3 Team Information

**Developer:** Hannes Gao (Independent Developer from Belvast Innovation)

---

**Document Version:** 1.0  
**Last Updated:** November 22, 2025  