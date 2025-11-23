'use client';

import { useState } from 'react';
import { useAccount, useWriteContract, useReadContract } from 'wagmi';
import { parseEther, parseUnits } from 'viem';
import { CONTRACTS, FIXED_EXCHANGE_ABI, ZKK_ABI, MOCK_USDC_ABI } from '@/lib/contracts';

export function DualSwapInterface() {
  const { address, chain } = useAccount();
  const [zkkAmount, setZkkAmount] = useState('10');

  const isSepolia = chain?.id === 11155111;
  const zkkContract = isSepolia ? CONTRACTS.sepolia.ZKK : CONTRACTS.baseSepolia.ZKK;
  const exchangeContract = CONTRACTS.sepolia.FIXED_EXCHANGE;

  const { data: zkkBalance } = useReadContract({
    address: zkkContract,
    abi: ZKK_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: expectedOutput } = useReadContract({
    address: exchangeContract,
    abi: FIXED_EXCHANGE_ABI,
    functionName: 'getOutputAmount',
    args: zkkAmount ? [parseEther(zkkAmount)] : undefined,
  });

  const { writeContract: approveZKK } = useWriteContract();
  const { writeContract: executeRedeem } = useWriteContract();

  const handleFixedPoolSwap = async () => {
    if (!address || !zkkAmount) return;

    try {
      // First approve ZKK
      approveZKK({
        address: zkkContract,
        abi: ZKK_ABI,
        functionName: 'approve',
        args: [exchangeContract, parseEther(zkkAmount)],
      });

      // Then redeem (in production, wait for approval first)
      setTimeout(() => {
        executeRedeem({
          address: exchangeContract,
          abi: FIXED_EXCHANGE_ABI,
          functionName: 'redeem',
          args: [parseEther(zkkAmount), address],
        });
      }, 2000);
    } catch (error) {
      console.error('Swap error:', error);
    }
  };

  const fixedPoolOutput = expectedOutput ? Number(expectedOutput) / 1e6 : 0;
  const uniswapPoolOutput = Number(zkkAmount) * 0.99; // Simplified - dynamic fee

  return (
    <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8">
      <h2 className="text-2xl font-bold mb-6 text-gray-900 dark:text-white">
        Dual Pool Comparison
      </h2>

      {/* Input Section */}
      <div className="mb-8">
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-2">
          ZKK Amount to Swap
        </label>
        <input
          type="number"
          value={zkkAmount}
          onChange={(e) => setZkkAmount(e.target.value)}
          className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
          placeholder="10"
        />
        {zkkBalance && (
          <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
            Balance: {(Number(zkkBalance) / 1e18).toFixed(2)} ZKK
          </p>
        )}
      </div>

      {/* Pool Comparison Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Fixed Pool */}
        <div className="border-2 border-green-500 dark:border-green-400 rounded-xl p-6 bg-green-50 dark:bg-green-900/20">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-lg text-gray-900 dark:text-white">Fixed Pool</h3>
            <span className="text-xs bg-green-600 text-white px-2 py-1 rounded">
              0% Fee
            </span>
          </div>

          <div className="space-y-3">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-300">Exchange Rate</p>
              <p className="text-2xl font-bold text-green-600 dark:text-green-400">1:1</p>
            </div>

            <div>
              <p className="text-sm text-gray-600 dark:text-gray-300">You Get</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {fixedPoolOutput.toFixed(2)} USDC
              </p>
            </div>

            <button
              onClick={handleFixedPoolSwap}
              disabled={!address}
              className="w-full bg-green-600 text-white font-bold py-3 px-4 rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
            >
              Swap on Fixed Pool
            </button>

            <p className="text-xs text-gray-500 dark:text-gray-400 text-center">
              ✅ Guaranteed • Project-Controlled
            </p>
          </div>
        </div>

        {/* Uniswap v4 Pool */}
        <div className="border-2 border-purple-500 dark:border-purple-400 rounded-xl p-6 bg-purple-50 dark:bg-purple-900/20">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-lg text-gray-900 dark:text-white">Uniswap v4 Pool</h3>
            <span className="text-xs bg-purple-600 text-white px-2 py-1 rounded">
              Dynamic Fee
            </span>
          </div>

          <div className="space-y-3">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-300">Exchange Rate</p>
              <p className="text-2xl font-bold text-purple-600 dark:text-purple-400">
                ~{(uniswapPoolOutput / Number(zkkAmount || 1)).toFixed(4)}:1
              </p>
            </div>

            <div>
              <p className="text-sm text-gray-600 dark:text-gray-300">You Get</p>
              <p className="text-3xl font-bold text-gray-900 dark:text-white">
                {uniswapPoolOutput.toFixed(2)} USDC
              </p>
            </div>

            <button
              disabled
              className="w-full bg-purple-600 text-white font-bold py-3 px-4 rounded-lg opacity-50 cursor-not-allowed"
            >
              Swap on Uniswap v4 (Coming Soon)
            </button>

            <p className="text-xs text-gray-500 dark:text-gray-400 text-center">
              📊 Market-Driven • Public Liquidity
            </p>
          </div>
        </div>
      </div>

      {/* Price Differential Indicator */}
      {Math.abs(fixedPoolOutput - uniswapPoolOutput) > 0.05 && (
        <div className="mt-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-400 dark:border-yellow-600 rounded-lg">
          <p className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
            ⚠️ Price differential detected: {Math.abs(fixedPoolOutput - uniswapPoolOutput).toFixed(2)} USDC
            <br />
            <span className="text-xs">Arbitrage opportunity may exist!</span>
          </p>
        </div>
      )}
    </div>
  );
}
