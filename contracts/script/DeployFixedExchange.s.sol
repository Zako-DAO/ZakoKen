// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FixedExchange.sol";

/**
 * @title DeployFixedExchange
 * @notice Deploy FixedExchange contract
 * @dev Usage: forge script script/DeployFixedExchange.s.sol:DeployFixedExchange --rpc-url sepolia --broadcast --verify
 *
 * Prerequisites:
 * - ZKK_OFT_SEPOLIA must be set in .env
 * - MOCK_USDC_SEPOLIA must be set in .env
 */
contract DeployFixedExchange is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load required addresses
        address zkkAddress = vm.envAddress("ZKK_OFT_SEPOLIA");
        address usdcAddress = vm.envAddress("MOCK_USDC_SEPOLIA");

        vm.startBroadcast(deployerPrivateKey);

        console.log("==================================================");
        console.log("Deploying FixedExchange");
        console.log("==================================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("ZKK Token:", zkkAddress);
        console.log("USDC Token:", usdcAddress);
        console.log("==================================================");

        // Deploy FixedExchange
        FixedExchange exchange = new FixedExchange(
            zkkAddress,
            usdcAddress
        );

        console.log("\nFixedExchange deployed to:", address(exchange));
        console.log("ZKK Token:", address(exchange.zkk()));
        console.log("USDC Token:", address(exchange.usdc()));
        console.log("Exchange Rate:", exchange.exchangeRate());
        console.log("Paused:", exchange.paused());

        console.log("\n==================================================");
        console.log("Deployment completed!");
        console.log("==================================================");
        console.log("\nAdd to .env:");
        console.log("FIXED_EXCHANGE_SEPOLIA=", address(exchange));
        console.log("\nNext steps:");
        console.log("1. Deposit USDC collateral:");
        console.log("   cast send <USDC> \"approve(address,uint256)\" <EXCHANGE> <AMOUNT> --rpc-url sepolia --private-key $PRIVATE_KEY");
        console.log("   cast send <EXCHANGE> \"depositCollateral(uint256)\" <AMOUNT> --rpc-url sepolia --private-key $PRIVATE_KEY");
        console.log("==================================================");

        vm.stopBroadcast();
    }
}
