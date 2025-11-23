// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ZakoKenHook
 * @notice Uniswap v4 hook for ZKK-USDC pool with dynamic fees
 * @dev Implements dynamic fee based on price deviation from 1:1 peg
 */
contract ZakoKenHook is IHooks, Ownable {
    using PoolIdLibrary for PoolKey;

    // ============ Events ============

    event SwapExecuted(
        PoolId indexed poolId,
        address indexed swapper,
        bool zeroForOne,
        int256 amountSpecified,
        uint24 dynamicFee,
        uint256 timestamp
    );

    event PriceRecorded(
        PoolId indexed poolId,
        uint160 sqrtPriceX96,
        uint256 timestamp
    );

    event ArbitrageDetected(
        PoolId indexed poolId,
        uint256 priceDeviation,
        uint256 timestamp
    );

    // ============ Errors ============

    error InvalidPoolManager();
    error InvalidFee();

    // ============ State Variables ============

    /// @notice Base swap fee (5 basis points = 0.05%)
    uint24 public constant BASE_FEE = 500;

    /// @notice Minimum fee (1 basis point = 0.01%)
    uint24 public constant MIN_FEE = 100;

    /// @notice Maximum fee (200 basis points = 2%)
    uint24 public constant MAX_FEE = 20000;

    /// @notice Target price (1:1 = 1e18)
    uint256 public constant TARGET_PRICE = 1e18;

    /// @notice Price deviation threshold for arbitrage alert (50 basis points = 0.5%)
    uint256 public constant ARBITRAGE_THRESHOLD = 50;

    /// @notice Last recorded price for each pool
    mapping(PoolId => uint160) public lastPrice;

    /// @notice Swap count for each pool
    mapping(PoolId => uint256) public swapCount;

    /// @notice Pool manager reference
    IPoolManager public immutable poolManager;

    // ============ Constructor ============

    constructor(
        IPoolManager _poolManager
    ) {
        if (address(_poolManager) == address(0)) revert InvalidPoolManager();
        poolManager = _poolManager;
    }

    // ============ Modifier ============

    modifier onlyPoolManager() {
        require(
            msg.sender == address(poolManager),
            "Only pool manager can call"
        );
        _;
    }

    // ============ Hook Implementation ============

    /**
     * @notice Called before each swap to calculate dynamic fee
     */
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata // hookData - unused
    )
        external
        override
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId poolId = key.toId();

        // Calculate dynamic fee based on price deviation
        uint24 dynamicFee = calculateDynamicFee(poolId);

        emit SwapExecuted(
            poolId,
            sender,
            params.zeroForOne,
            params.amountSpecified,
            dynamicFee,
            block.timestamp
        );

        return (
            IHooks.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            dynamicFee
        );
    }

    /**
     * @notice Called after each swap to record price
     * @dev Simplified for hackathon demo - price tracking via external calls
     */
    function afterSwap(
        address, // sender - unused
        PoolKey calldata key,
        SwapParams calldata, // params - unused
        BalanceDelta, // delta - unused
        bytes calldata // hookData - unused
    ) external override onlyPoolManager returns (bytes4, int128) {
        PoolId poolId = key.toId();

        // Increment swap count
        swapCount[poolId]++;

        // Note: For hackathon demo, price can be tracked off-chain
        // or updated via separate price oracle function

        return (IHooks.afterSwap.selector, 0);
    }

    /**
     * @notice Manually update price (for demo purposes)
     * @param poolId Pool identifier
     * @param sqrtPriceX96 Square root price in X96 format
     */
    function updatePrice(
        PoolId poolId,
        uint160 sqrtPriceX96
    ) external onlyOwner {
        lastPrice[poolId] = sqrtPriceX96;

        emit PriceRecorded(poolId, sqrtPriceX96, block.timestamp);

        // Check for arbitrage opportunity
        uint256 currentPrice = sqrtPriceToPrice(sqrtPriceX96);
        uint256 deviation = calculateDeviation(currentPrice);

        if (deviation > ARBITRAGE_THRESHOLD) {
            emit ArbitrageDetected(poolId, deviation, block.timestamp);
        }
    }

    // ============ Required IHooks Implementation (Unused) ============

    function beforeInitialize(
        address,
        PoolKey calldata,
        uint160
    ) external pure override returns (bytes4) {
        revert("Not implemented");
    }

    function afterInitialize(
        address,
        PoolKey calldata,
        uint160,
        int24
    ) external pure override returns (bytes4) {
        revert("Not implemented");
    }

    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Not implemented");
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure override returns (bytes4, BalanceDelta) {
        revert("Not implemented");
    }

    function beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Not implemented");
    }

    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure override returns (bytes4, BalanceDelta) {
        revert("Not implemented");
    }

    function beforeDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Not implemented");
    }

    function afterDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Not implemented");
    }

    // ============ Internal Functions ============

    /**
     * @notice Calculate dynamic fee based on price deviation
     * @param poolId Pool identifier
     * @return fee Dynamic fee in hundredths of basis points
     */
    function calculateDynamicFee(
        PoolId poolId
    ) internal view returns (uint24 fee) {
        uint160 currentSqrtPrice = lastPrice[poolId];

        if (currentSqrtPrice == 0) {
            // No price history, use base fee
            return BASE_FEE;
        }

        // Convert sqrt price to regular price
        uint256 currentPrice = sqrtPriceToPrice(currentSqrtPrice);

        // Calculate deviation from 1:1 peg (in basis points)
        uint256 deviation = calculateDeviation(currentPrice);

        // Dynamic fee formula:
        // fee = BASE_FEE + (deviation * multiplier)
        // Higher deviation = higher fee to discourage destabilizing swaps
        fee = BASE_FEE + uint24(deviation * 2);

        // Clamp fee within bounds
        if (fee < MIN_FEE) fee = MIN_FEE;
        if (fee > MAX_FEE) fee = MAX_FEE;

        return fee;
    }

    /**
     * @notice Convert sqrt price X96 to regular price
     * @param sqrtPriceX96 Square root price in X96 format
     * @return price Regular price scaled by 1e18
     */
    function sqrtPriceToPrice(
        uint160 sqrtPriceX96
    ) internal pure returns (uint256 price) {
        // sqrtPriceX96 = sqrt(price) * 2^96
        // price = (sqrtPriceX96 / 2^96)^2
        uint256 scaledPrice = uint256(sqrtPriceX96);
        price = (scaledPrice * scaledPrice * 1e18) >> 192;
        return price;
    }

    /**
     * @notice Calculate price deviation from target (in basis points)
     * @param currentPrice Current price (scaled by 1e18)
     * @return deviation Deviation in basis points
     */
    function calculateDeviation(
        uint256 currentPrice
    ) internal pure returns (uint256 deviation) {
        if (currentPrice > TARGET_PRICE) {
            deviation =
                ((currentPrice - TARGET_PRICE) * 10000) /
                TARGET_PRICE;
        } else {
            deviation =
                ((TARGET_PRICE - currentPrice) * 10000) /
                TARGET_PRICE;
        }
        return deviation;
    }

    // ============ View Functions ============

    /**
     * @notice Get current price for a pool
     * @param poolId Pool identifier
     * @return price Current price scaled by 1e18
     */
    function getCurrentPrice(
        PoolId poolId
    ) external view returns (uint256 price) {
        uint160 sqrtPriceX96 = lastPrice[poolId];
        if (sqrtPriceX96 == 0) return 0;
        return sqrtPriceToPrice(sqrtPriceX96);
    }

    /**
     * @notice Get current fee for a pool
     * @param poolId Pool identifier
     * @return fee Current dynamic fee
     */
    function getCurrentFee(PoolId poolId) external view returns (uint24 fee) {
        return calculateDynamicFee(poolId);
    }

    /**
     * @notice Check if arbitrage opportunity exists
     * @param poolId Pool identifier
     * @return exists Whether arbitrage opportunity exists
     * @return deviation Price deviation in basis points
     */
    function checkArbitrageOpportunity(
        PoolId poolId
    ) external view returns (bool exists, uint256 deviation) {
        uint160 sqrtPriceX96 = lastPrice[poolId];
        if (sqrtPriceX96 == 0) return (false, 0);

        uint256 currentPrice = sqrtPriceToPrice(sqrtPriceX96);
        deviation = calculateDeviation(currentPrice);
        exists = deviation > ARBITRAGE_THRESHOLD;

        return (exists, deviation);
    }
}
