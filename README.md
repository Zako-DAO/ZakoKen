# ZakoKen (雜魚券)

**A Dynamic Fundraising Stablecoin Protocol for Open-Source Projects**

ZakoKen combines LayerZero's Omnichain Fungible Token (OFT) standard with Uniswap v4 hooks to create a dual-liquidity mechanism that stabilizes token prices while maximizing project treasury value through controlled arbitrage.

🏆 **ETHGlobal Buenos Aires Hackathon Project**
- 🔗 LayerZero: Cross-chain token with compose messages
- 🦄 Uniswap Foundation: Dynamic fee hooks for stable-asset AMM
- 🔵 Circle (Optional): Native USDC integration on Arc

---

## 🎯 Quick Links

- **Hackathon Guide**: [docs/zakoken_hackathon_guide.md](docs/zakoken_hackathon_guide.md) ⚡ **START HERE!**
  - Quick start checklist (15 min)
  - Complete 18-hour execution plan
  - Technical specifications
  - Submission requirements
- **Architecture**: [docs/zakoken_architecture_doc.md](docs/zakoken_architecture_doc.md)
- **Development**: [docs/zakoken_development_doc.md](docs/zakoken_development_doc.md)
- **Deployment**: [docs/zakoken_deployment_doc.md](docs/zakoken_deployment_doc.md)

---

## 💡 The Problem

Traditional fundraising tokens suffer from:
- Pump-and-dump schemes harming late participants
- Unfair token concentration benefiting early investors
- Lack of price stability in secondary markets
- Project treasury depletion without sustainable value capture

## ✨ The Solution

ZakoKen implements a **dual-liquidity mechanism**:

1. **Fixed Pool**: Project-controlled 1:1 USDC redemption (guaranteed, 0% fee)
2. **Uniswap v4 Pool**: Market-driven dynamic pricing (public, dynamic fee)
3. **Project-as-Arbitrageur**: Treasury captures profit from price differentials
4. **Cross-Chain**: LayerZero OFT enables omnichain accessibility

### Key Innovation: Compose Messages for Transparency

Every token mint/burn attaches off-chain transaction metadata via LayerZero compose messages:
```solidity
struct ComposeMsg {
    bytes32 transactionHash;    // Off-chain tx identifier
    uint256 timestamp;          // Transaction time
    uint256 amount;             // Minted/burned amount
    address recipient;          // Token recipient
    bytes32 projectId;          // Project ID
    uint256 greedIndex;         // Greed multiplier
}
```

---

## 🏗️ Architecture (Simplified for Demo)

### Deployment Chains
- **Ethereum Sepolia**: Full deployment (ZKK-OFT + Fixed Exchange + Uniswap v4 Hook)
- **Base Sepolia**: ZKK-OFT for cross-chain demo
- **Arc Testnet** (Optional): Standalone deployment with native USDC

### Project Structure
```
ZakoKen/
├── contracts/           # Smart contracts (Hardhat)
│   ├── src/            # Solidity source files
│   ├── script/         # Deployment scripts
│   └── test/           # Contract tests
├── frontend/           # React frontend application
│   ├── src/
│   │   ├── components/ # React components
│   │   ├── hooks/      # Custom hooks
│   │   └── utils/      # Helper functions
│   └── public/
├── docs/               # Documentation
└── EXECUTION_PLAN.md   # 18-hour sprint plan
```

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- pnpm
- Wallet with Sepolia ETH and Base Sepolia ETH

### Installation
```bash
# Clone repository
git clone https://github.com/ZakoDAO/ZakoKen.git
cd ZakoKen

# Install dependencies
pnpm install

# Setup environment
cp .env.example .env
# Edit .env with your private key and RPC URLs
```

### Deploy Contracts
```bash
# Deploy to Sepolia
pnpm hardhat run scripts/deploy-zkk.ts --network sepolia

# Deploy to Base Sepolia
pnpm hardhat run scripts/deploy-zkk.ts --network baseSepolia

# Configure LayerZero peers
pnpm hardhat run scripts/configure-layerzero.ts
```

### Run Frontend
```bash
cd frontend
pnpm install
pnpm dev
# Open http://localhost:5173
```

---

## 🎮 Demo Flow

1. **Connect Wallet** → MetaMask (Sepolia or Base Sepolia)
2. **Simulate Off-Chain Transaction** → Click button to mint ZKK tokens
3. **View Dual Pools**:
   - Fixed Pool: 1:1 USDC, 0% fee
   - Uniswap Pool: ~0.998 USDC, 0.05% fee
4. **Swap Tokens** → Choose pool and redeem for USDC
5. **Watch Arbitrage** → Project captures price differential profit
6. **Cross-Chain Transfer** → Send ZKK Sepolia → Base Sepolia via LayerZero

---

## 🏆 Hackathon Tracks

### LayerZero ($20,000)
✅ OFT standard implementation
✅ Compose messages for off-chain metadata
✅ Cross-chain Sepolia ↔ Base Sepolia
✅ Custom `lzCompose()` handler

### Uniswap Foundation ($10,000)
✅ v4 Hook with `beforeSwap()` and `afterSwap()`
✅ Dynamic fee based on price deviation
✅ Stable-asset AMM logic for ZKK-USDC
✅ Arbitrage opportunity detection

### Circle (Optional $4,000)
⭕ Deploy on Arc Public Testnet
⭕ Native USDC integration
⭕ Programmable redemption logic

---

## 📚 Documentation

All documentation is in the `docs/` directory. See [docs/README.md](docs/README.md) for complete index.

**Primary Document** (All-in-One):
- [**Hackathon Guide**](docs/zakoken_hackathon_guide.md) ⭐ - Complete guide with quick start, 18-hour plan, and specifications

**Supporting Documents**:
- [**Architecture**](docs/zakoken_architecture_doc.md) - Full technical specification
- [**Development**](docs/zakoken_development_doc.md) - Development instructions
- [**Deployment**](docs/zakoken_deployment_doc.md) - Deployment steps

---

## 🔗 Resources

### Official Documentation
- [LayerZero V2 Docs](https://docs.layerzero.network/v2)
- [Uniswap v4 Docs](https://docs.uniswap.org/contracts/v4)
- [Circle Arc Docs](https://docs.arc.network)

### Testnet Faucets
- [Sepolia ETH Faucet](https://sepoliafaucet.com)
- [Base Sepolia Faucet](https://faucet.quicknode.com/base/sepolia)
- [Circle USDC Faucet](https://faucet.circle.com)

### Explorers
- [LayerZero Scan](https://testnet.layerzeroscan.com)
- [Sepolia Etherscan](https://sepolia.etherscan.io)
- [Base Sepolia Explorer](https://sepolia.basescan.org)

---

## 📦 Tech Stack

**Smart Contracts**:
- Solidity ^0.8.20
- Hardhat + Ethers v6
- LayerZero OFT SDK
- Uniswap v4 Core & Periphery
- OpenZeppelin Contracts

**Frontend**:
- React 18 + TypeScript
- Vite
- RainbowKit + wagmi
- TailwindCSS
- ethers.js / viem

---

## 🤝 Contributing

This is a hackathon project. Contributions, issues, and feature requests are welcome!

---

## 📝 License

MIT License - see [LICENSE](LICENSE) for details

---

## 👥 Team

**Developer**: Hannes Gao (Belvast Innovation)

**Built for**: ETHGlobal Buenos Aires 2025

