// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title FixedExchange
 * @notice Project-controlled 1:1 USDC redemption pool with zero fees
 * @dev Guaranteed fixed-price exchange for ZKK tokens
 */
contract FixedExchange is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Events ============

    event Redeemed(
        address indexed user,
        uint256 zkkAmount,
        uint256 usdcAmount,
        uint256 timestamp
    );

    event CollateralDeposited(
        address indexed depositor,
        uint256 amount,
        uint256 timestamp
    );

    event CollateralWithdrawn(
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );

    event ExchangeRateUpdated(uint256 oldRate, uint256 newRate);

    // ============ Errors ============

    error InvalidAmount();
    error InsufficientCollateral();
    error InvalidToken();
    error InvalidRecipient();

    // ============ State Variables ============

    /// @notice ZKK token contract
    IERC20 public immutable zkk;

    /// @notice USDC token contract
    IERC20 public immutable usdc;

    /// @notice Exchange rate (in basis points, 10000 = 1:1)
    /// @dev Allows for future adjustments if needed
    uint256 public exchangeRate;

    /// @notice Constant for basis points calculation
    uint256 public constant BASIS_POINTS = 10000;

    /// @notice Total USDC collateral deposited
    uint256 public totalCollateral;

    /// @notice Total redemptions processed
    uint256 public totalRedemptions;

    // ============ Constructor ============

    /**
     * @param _zkk ZKK token address
     * @param _usdc USDC token address
     */
    constructor(
        address _zkk,
        address _usdc
    ) {
        if (_zkk == address(0) || _usdc == address(0)) revert InvalidToken();

        zkk = IERC20(_zkk);
        usdc = IERC20(_usdc);
        exchangeRate = BASIS_POINTS; // 1:1 by default
    }

    // ============ External Functions ============

    /**
     * @notice Redeem ZKK tokens for USDC at 1:1 ratio
     * @param zkkAmount Amount of ZKK tokens to redeem
     */
    function redeem(uint256 zkkAmount) external whenNotPaused nonReentrant {
        if (zkkAmount == 0) revert InvalidAmount();

        // Calculate USDC amount (1:1 ratio, accounting for decimals)
        uint256 usdcAmount = (zkkAmount * exchangeRate) / BASIS_POINTS;

        // Adjust for decimal difference (ZKK is 18 decimals, USDC is 6)
        usdcAmount = usdcAmount / 1e12;

        // Check collateral sufficiency
        uint256 availableCollateral = usdc.balanceOf(address(this));
        if (availableCollateral < usdcAmount) revert InsufficientCollateral();

        // Burn ZKK tokens
        zkk.safeTransferFrom(msg.sender, address(this), zkkAmount);

        // Transfer USDC to user
        usdc.safeTransfer(msg.sender, usdcAmount);

        // Update state
        totalRedemptions += zkkAmount;

        emit Redeemed(msg.sender, zkkAmount, usdcAmount, block.timestamp);
    }

    /**
     * @notice Deposit USDC collateral to back ZKK redemptions
     * @param amount Amount of USDC to deposit
     */
    function depositCollateral(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();

        usdc.safeTransferFrom(msg.sender, address(this), amount);
        totalCollateral += amount;

        emit CollateralDeposited(msg.sender, amount, block.timestamp);
    }

    /**
     * @notice Withdraw USDC collateral (owner only)
     * @param amount Amount of USDC to withdraw
     * @param recipient Recipient address
     */
    function withdrawCollateral(
        uint256 amount,
        address recipient
    ) external onlyOwner {
        if (amount == 0) revert InvalidAmount();
        if (recipient == address(0)) revert InvalidRecipient();

        uint256 availableCollateral = usdc.balanceOf(address(this));
        if (availableCollateral < amount) revert InsufficientCollateral();

        usdc.safeTransfer(recipient, amount);
        totalCollateral -= amount;

        emit CollateralWithdrawn(recipient, amount, block.timestamp);
    }

    /**
     * @notice Update exchange rate (owner only)
     * @param newRate New exchange rate in basis points
     */
    function setExchangeRate(uint256 newRate) external onlyOwner {
        if (newRate == 0) revert InvalidAmount();

        uint256 oldRate = exchangeRate;
        exchangeRate = newRate;

        emit ExchangeRateUpdated(oldRate, newRate);
    }

    /**
     * @notice Pause redemptions (emergency only)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause redemptions
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ View Functions ============

    /**
     * @notice Get available USDC collateral
     */
    function getAvailableCollateral() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /**
     * @notice Calculate USDC output for given ZKK input
     * @param zkkAmount Amount of ZKK tokens
     * @return usdcAmount Amount of USDC to receive
     */
    function getOutputAmount(
        uint256 zkkAmount
    ) external view returns (uint256 usdcAmount) {
        usdcAmount = (zkkAmount * exchangeRate) / BASIS_POINTS;
        usdcAmount = usdcAmount / 1e12; // Adjust for decimal difference
    }

    /**
     * @notice Check if redemption is possible
     * @param zkkAmount Amount of ZKK to redeem
     * @return possible Whether redemption is possible
     */
    function canRedeem(uint256 zkkAmount) external view returns (bool) {
        if (paused()) return false;
        if (zkkAmount == 0) return false;

        uint256 usdcAmount = (zkkAmount * exchangeRate) / BASIS_POINTS;
        usdcAmount = usdcAmount / 1e12;

        return usdc.balanceOf(address(this)) >= usdcAmount;
    }
}
