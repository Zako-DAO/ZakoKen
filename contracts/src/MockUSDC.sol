// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDC
 * @notice Mock USDC token for testing purposes
 * @dev 6 decimals to match real USDC
 */
contract MockUSDC is ERC20, Ownable {
    constructor() ERC20("Mock USDC", "USDC") {
        // Mint initial supply to deployer (1M USDC)
        _mint(msg.sender, 1_000_000 * 10 ** 6);
    }

    /**
     * @notice USDC uses 6 decimals
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /**
     * @notice Mint new tokens (owner only, for testing)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Faucet function for easy testing
     */
    function faucet() external {
        _mint(msg.sender, 10000 * 10 ** 6); // 10,000 USDC
    }
}
