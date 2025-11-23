'use client';

import { useState } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useReadContract } from 'wagmi';
import { parseEther, keccak256, toBytes } from 'viem';
import { CONTRACTS, ZKK_ABI } from '@/lib/contracts';

export function MintSimulator() {
  const { address, chain } = useAccount();
  const [amount, setAmount] = useState('100');
  const [isMinting, setIsMinting] = useState(false);

  const contractAddress = chain?.id === 11155111
    ? CONTRACTS.sepolia.ZKK
    : CONTRACTS.baseSepolia.ZKK;

  const { data: balance } = useReadContract({
    address: contractAddress,
    abi: ZKK_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { writeContract, data: hash } = useWriteContract();

  const { isLoading: isConfirming } = useWaitForTransactionReceipt({
    hash,
  });

  const handleMint = async () => {
    if (!address || !amount) return;

    try {
      setIsMinting(true);

      // Generate simulated off-chain transaction hash
      const txHash = keccak256(toBytes(`tx-${Date.now()}-${address}`));
      const projectId = keccak256(toBytes('zakoken-demo'));

      writeContract({
        address: contractAddress,
        abi: ZKK_ABI,
        functionName: 'mintWithCompose',
        args: [address, parseEther(amount), txHash, projectId],
      });
    } catch (error) {
      console.error('Mint error:', error);
    } finally {
      setIsMinting(false);
    }
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8">
      <h2 className="text-2xl font-bold mb-6 text-gray-900 dark:text-white">
        Simulate Off-Chain Transaction
      </h2>

      <div className="space-y-6">
        {/* Balance Display */}
        {address && balance !== undefined && (
          <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
            <p className="text-sm text-gray-600 dark:text-gray-300">Your ZKK Balance</p>
            <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">
              {(Number(balance) / 1e18).toLocaleString()} ZKK
            </p>
          </div>
        )}

        {/* Mint Amount Input */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-2">
            Amount to Mint (ZKK)
          </label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
            placeholder="100"
          />
        </div>

        {/* Mint Button */}
        <button
          onClick={handleMint}
          disabled={!address || isMinting || isConfirming}
          className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold py-4 px-6 rounded-lg hover:from-blue-700 hover:to-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all transform hover:scale-105"
        >
          {isConfirming ? (
            'Confirming...'
          ) : isMinting ? (
            'Minting...'
          ) : (
            '🚀 Simulate Off-Chain Transaction & Mint ZKK'
          )}
        </button>

        {/* Info Text */}
        <p className="text-xs text-gray-500 dark:text-gray-400 text-center">
          Simulates an off-chain transaction and mints ZKK tokens with a compose message.
          <br />
          The greed model will adjust the final amount based on your activity.
        </p>

        {/* Transaction Status */}
        {hash && (
          <div className="mt-4 p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
            <p className="text-sm text-green-800 dark:text-green-200">
              ✅ Transaction submitted!
              <a
                href={`https://${chain?.id === 11155111 ? 'sepolia.' : 'base-sepolia.'}etherscan.io/tx/${hash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="ml-2 underline hover:text-green-600"
              >
                View on Etherscan
              </a>
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
