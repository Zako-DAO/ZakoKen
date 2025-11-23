// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockUSDC.sol";

/**
 * @title DeployMockUSDC
 * @notice Deploy MockUSDC token for testing
 * @dev Usage: forge script script/DeployMockUSDC.s.sol:DeployMockUSDC --rpc-url sepolia --broadcast --verify
 */
contract DeployMockUSDC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("==================================================");
        console.log("Deploying MockUSDC");
        console.log("==================================================");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Chain ID:", block.chainid);
        console.log("==================================================");

        // Deploy MockUSDC
        MockUSDC usdc = new MockUSDC();

        console.log("\nMockUSDC deployed to:", address(usdc));
        console.log("Symbol:", usdc.symbol());
        console.log("Decimals:", usdc.decimals());
        console.log("Initial balance:", usdc.balanceOf(vm.addr(deployerPrivateKey)));

        console.log("\n==================================================");
        console.log("Deployment completed!");
        console.log("==================================================");
        console.log("\nAdd to .env:");
        console.log("MOCK_USDC_SEPOLIA=", address(usdc));
        console.log("==================================================");

        vm.stopBroadcast();
    }
}
