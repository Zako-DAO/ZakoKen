'use client';

import { useState, useEffect } from 'react';

export function ArbitrageDisplay() {
  const [fixedPrice, setFixedPrice] = useState(1.0);
  const [uniswapPrice, setUniswapPrice] = useState(0.99);

  const priceDiff = Math.abs(fixedPrice - uniswapPrice);
  const priceDiffPercent = (priceDiff / fixedPrice) * 100;
  const hasOpportunity = priceDiffPercent > 0.5;

  // Simulate price fluctuations for demo
  useEffect(() => {
    const interval = setInterval(() => {
      setUniswapPrice(0.98 + Math.random() * 0.04); // 0.98 - 1.02
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-6 h-full">
      <h2 className="text-xl font-bold mb-6 text-gray-900 dark:text-white">
        Arbitrage Monitor
      </h2>

      <div className="space-y-4">
        {/* Fixed Pool Price */}
        <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-4">
          <p className="text-sm text-gray-600 dark:text-gray-300">Fixed Pool</p>
          <p className="text-2xl font-bold text-green-600 dark:text-green-400">
            ${fixedPrice.toFixed(4)}
          </p>
        </div>

        {/* Uniswap Pool Price */}
        <div className="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4">
          <p className="text-sm text-gray-600 dark:text-gray-300">Uniswap v4</p>
          <p className="text-2xl font-bold text-purple-600 dark:text-purple-400">
            ${uniswapPrice.toFixed(4)}
          </p>
        </div>

        {/* Price Differential */}
        <div className={`rounded-lg p-4 ${hasOpportunity ? 'bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-400' : 'bg-gray-50 dark:bg-gray-700'}`}>
          <p className="text-sm text-gray-600 dark:text-gray-300">Price Differential</p>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">
            {priceDiffPercent.toFixed(2)}%
          </p>
        </div>

        {/* Arbitrage Opportunity Alert */}
        {hasOpportunity && (
          <div className="bg-yellow-100 dark:bg-yellow-900/30 border-2 border-yellow-500 rounded-lg p-4 animate-pulse">
            <p className="font-bold text-yellow-800 dark:text-yellow-200 mb-2">
              ⚡ Arbitrage Opportunity!
            </p>
            <p className="text-xs text-yellow-700 dark:text-yellow-300">
              Price differential exceeds 0.5% threshold.
              Bot can profit by buying from cheaper pool and selling to expensive pool.
            </p>
          </div>
        )}

        {/* Info Box */}
        <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 mt-6">
          <p className="text-xs text-gray-600 dark:text-gray-300">
            <strong>How it works:</strong>
            <br />
            The project-controlled arbitrage bot monitors price differentials.
            When deviation exceeds 0.5%, it executes profitable trades to stabilize prices and capture treasury value.
          </p>
        </div>
      </div>
    </div>
  );
}
