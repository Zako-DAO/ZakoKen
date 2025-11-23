// Contract addresses (fill after deployment)
export const CONTRACTS = {
  sepolia: {
    ZKK: process.env.NEXT_PUBLIC_ZKK_ADDRESS_SEPOLIA as `0x${string}` || '0x0000000000000000000000000000000000000000',
    FIXED_EXCHANGE: process.env.NEXT_PUBLIC_FIXED_EXCHANGE_SEPOLIA as `0x${string}` || '0x0000000000000000000000000000000000000000',
    MOCK_USDC: process.env.NEXT_PUBLIC_MOCK_USDC_SEPOLIA as `0x${string}` || '0x0000000000000000000000000000000000000000',
  },
  baseSepolia: {
    ZKK: process.env.NEXT_PUBLIC_ZKK_ADDRESS_BASE_SEPOLIA as `0x${string}` || '0x0000000000000000000000000000000000000000',
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
      { name: 'recipient', type: 'address' },
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
