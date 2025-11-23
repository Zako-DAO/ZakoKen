# ZakoKen Frontend

Next.js frontend for ZakoKen (雜魚券) - Dynamic Fundraising Stablecoin Demo

## Features

- 🔗 **Wallet Connection**: RainbowKit integration with Sepolia & Base Sepolia support
- 💰 **Mint Simulator**: Simulate off-chain transactions and mint ZKK tokens with compose messages
- 🔄 **Dual Pool Comparison**: Side-by-side comparison of Fixed Pool (1:1) vs Uniswap v4 Pool (dynamic)
- 📊 **Arbitrage Monitor**: Real-time price differential tracking and opportunity detection

## Quick Start

```bash
# Install dependencies
pnpm install

# Copy environment template
cp .env.example .env.local

# Fill in your WalletConnect Project ID and contract addresses

# Run development server
pnpm dev

# Build for production
pnpm build

# Deploy to Vercel
vercel --prod
```

## Environment Variables

Required environment variables (see `.env.example`):

- `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID`: Your WalletConnect project ID
- `NEXT_PUBLIC_ZKK_ADDRESS_SEPOLIA`: ZKK token contract address on Sepolia
- `NEXT_PUBLIC_FIXED_EXCHANGE_SEPOLIA`: Fixed Exchange contract address
- `NEXT_PUBLIC_MOCK_USDC_SEPOLIA`: Mock USDC contract address
- `NEXT_PUBLIC_ZKK_ADDRESS_BASE_SEPOLIA`: ZKK token on Base Sepolia (for cross-chain demo)

## Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Styling**: TailwindCSS
- **Web3**: wagmi + viem
- **Wallet**: RainbowKit
- **Language**: TypeScript

## Development

The app uses the Next.js App Router with TypeScript. Main structure:

```
frontend/
├── app/
│   ├── layout.tsx       # Root layout with providers
│   ├── page.tsx         # Main page
│   ├── providers.tsx    # Web3 providers setup
│   └── globals.css      # Global styles
├── components/
│   ├── MintSimulator.tsx
│   ├── DualSwapInterface.tsx
│   └── ArbitrageDisplay.tsx
└── lib/
    └── contracts.ts     # Contract ABIs and addresses
```

## Deployment

This app is optimized for Vercel deployment:

```bash
# Link to Vercel project
vercel link

# Deploy
vercel --prod
```

Make sure to set environment variables in the Vercel dashboard.

## License

MIT
