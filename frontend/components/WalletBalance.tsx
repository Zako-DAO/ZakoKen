'use client';

import { useState } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { CONTRACTS, ZKK_ABI, MOCK_USDC_ABI } from '@/lib/contracts';

export function WalletBalance() {
  const { address, chain } = useAccount();

  const isSepolia = chain?.id === 11155111;
  const zkkContract = isSepolia ? CONTRACTS.sepolia.ZKK : CONTRACTS.baseSepolia.ZKK;
  const usdcContract = isSepolia
    ? CONTRACTS.sepolia.MOCK_USDC
    : CONTRACTS.baseSepolia.MOCK_USDC;

  const { data: zkkBalance } = useReadContract({
    address: zkkContract,
    abi: ZKK_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: usdcBalance } = useReadContract({
    address: usdcContract,
    abi: MOCK_USDC_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  if (!address) {
    return null;
  }

  return (
    <div className="flex gap-4 items-center">
      {/* ZKK Balance */}
      <div className="bg-blue-100 dark:bg-blue-900/30 px-4 py-2 rounded-lg">
        <p className="text-xs text-gray-600 dark:text-gray-400">ZKK Balance</p>
        <p className="text-lg font-bold text-blue-600 dark:text-blue-400">
          {zkkBalance !== undefined
            ? (Number(zkkBalance) / 1e18).toLocaleString(undefined, {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              })
            : '...'}{' '}
          <span className="text-sm">ZKK</span>
        </p>
      </div>

      {/* USDC Balance */}
      <div className="bg-green-100 dark:bg-green-900/30 px-4 py-2 rounded-lg">
        <p className="text-xs text-gray-600 dark:text-gray-400">USDC Balance</p>
        <p className="text-lg font-bold text-green-600 dark:text-green-400">
          {usdcBalance !== undefined
            ? (Number(usdcBalance) / 1e6).toLocaleString(undefined, {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              })
            : '...'}{' '}
          <span className="text-sm">USDC</span>
        </p>
      </div>
    </div>
  );
}

export function FaucetButton() {
  const { address, chain } = useAccount();
  const [isClaiming, setIsClaiming] = useState(false);

  const isSepolia = chain?.id === 11155111;
  const usdcContract = isSepolia
    ? CONTRACTS.sepolia.MOCK_USDC
    : CONTRACTS.baseSepolia.MOCK_USDC;

  const { writeContract: claimFaucet, data: faucetHash } = useWriteContract();

  const { isLoading: isFaucetPending, isSuccess: isFaucetSuccess } = useWaitForTransactionReceipt({
    hash: faucetHash,
  });

  const handleClaimFaucet = () => {
    if (!address) return;
    setIsClaiming(true);
    claimFaucet({
      address: usdcContract,
      abi: MOCK_USDC_ABI,
      functionName: 'faucet',
    });
  };

  if (isFaucetSuccess && isClaiming) {
    setIsClaiming(false);
  }

  if (!address) {
    return null;
  }

  return (
    <button
      onClick={handleClaimFaucet}
      disabled={isFaucetPending || isClaiming}
      className="bg-green-600 hover:bg-green-700 text-white font-semibold px-4 py-2 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition-all text-sm"
    >
      {isFaucetPending || isClaiming ? '⏳ Claiming...' : isFaucetSuccess ? '✅ Claimed!' : '💰 Get Test USDC'}
    </button>
  );
}
