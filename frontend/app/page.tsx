'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { MintSimulator } from '@/components/MintSimulator';
import { DualSwapInterface } from '@/components/DualSwapInterface';
import { ArbitrageDisplay } from '@/components/ArbitrageDisplay';

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <header className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-2">
              ZakoKen (雜魚券)
            </h1>
            <p className="text-gray-600 dark:text-gray-300">
              Dynamic Fundraising Stablecoin - Hackathon Demo
            </p>
          </div>
          <div>
            <ConnectButton />
          </div>
        </header>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column - Mint Simulator */}
          <div className="lg:col-span-2">
            <MintSimulator />
          </div>

          {/* Right Column - Arbitrage Display */}
          <div>
            <ArbitrageDisplay />
          </div>

          {/* Full Width - Dual Swap Interface */}
          <div className="lg:col-span-3">
            <DualSwapInterface />
          </div>
        </div>

        {/* Footer */}
        <footer className="mt-12 text-center text-sm text-gray-500 dark:text-gray-400">
          <p>
            Built for ETHGlobal Buenos Aires • LayerZero + Uniswap v4 Demo
          </p>
          <p className="mt-2">
            <a
              href="https://github.com/zakodao"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-blue-600 dark:hover:text-blue-400"
            >
              GitHub
            </a>
            {' • '}
            <a
              href="https://etherscan.io"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-blue-600 dark:hover:text-blue-400"
            >
              Etherscan
            </a>
          </p>
        </footer>
      </div>
    </main>
  );
}
