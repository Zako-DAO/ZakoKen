/**
 * Deployed Contract Addresses
 * Last updated: November 23, 2025
 * See docs/zakoken_deployment_summary.md for full deployment details
 */
export const CONTRACTS = {
  sepolia: {
    ZKK: (process.env.NEXT_PUBLIC_ZKK_ADDRESS_SEPOLIA || '0x7462f4984a1551ACeE53ecAF3E2CCC6ffd6Ae4e1') as `0x${string}`,
    FIXED_EXCHANGE: (process.env.NEXT_PUBLIC_FIXED_EXCHANGE_SEPOLIA || '0xE041a461F79538D6bC156F32e69aAa78D7387Cc6') as `0x${string}`,
    MOCK_USDC: (process.env.NEXT_PUBLIC_MOCK_USDC_SEPOLIA || '0x8a6f2C4A6E72A5d1693f91CeF662E77F30ca06F2') as `0x${string}`,
  },
  baseSepolia: {
    ZKK: (process.env.NEXT_PUBLIC_ZKK_ADDRESS_BASE_SEPOLIA || '0x83f0D7A6a2eC2ee0cE5DaC3Bf9c9A323d6D6b755') as `0x${string}`,
    MOCK_USDC: (process.env.NEXT_PUBLIC_MOCK_USDC_BASE_SEPOLIA || '0x19EDeDbf11EdcF276288d7250DAE392E9F5a78Dd') as `0x${string}`,
  },
} as const;

// Simplified ABIs - only the functions we need for the demo
export const ZKK_ABI = [
  {
    type: 'function',
    name: 'mintWithCompose',
    inputs: [
      { name: 'to', type: 'address' },
      { name: 'amount', type: 'uint256' },
      { name: 'txHash', type: 'bytes32' },
      { name: 'projectId', type: 'bytes32' },
    ],
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'balanceOf',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'approve',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'totalSupply',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
] as const;

export const FIXED_EXCHANGE_ABI = [
  {
    type: 'function',
    name: 'redeem',
    inputs: [
      { name: 'zkkAmount', type: 'uint256' },
    ],
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'getOutputAmount',
    inputs: [{ name: 'zkkAmount', type: 'uint256' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'canRedeem',
    inputs: [{ name: 'zkkAmount', type: 'uint256' }],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'exchangeRate',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
] as const;

export const MOCK_USDC_ABI = [
  {
    type: 'function',
    name: 'balanceOf',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'approve',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'faucet',
    inputs: [],
    outputs: [],
    stateMutability: 'nonpayable',
  },
] as const;
