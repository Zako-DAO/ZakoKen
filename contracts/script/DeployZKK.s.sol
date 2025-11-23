// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ZKK.sol";

/**
 * @title DeployZKK
 * @notice Deploy ZKK OFT token
 * @dev Usage: forge script script/DeployZKK.s.sol:DeployZKK --rpc-url sepolia --broadcast --verify
 */
contract DeployZKK is Script {
    // LayerZero V2 Testnet Endpoints
    address constant LZ_ENDPOINT_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address constant LZ_ENDPOINT_BASE_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    // Default project ID
    bytes32 constant DEFAULT_PROJECT_ID = keccak256("ZakoKen-Demo-Project");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Determine LayerZero endpoint based on chain ID
        address lzEndpoint;
        string memory networkName;

        if (block.chainid == 11155111) {
            // Sepolia
            lzEndpoint = LZ_ENDPOINT_SEPOLIA;
            networkName = "SEPOLIA";
        } else if (block.chainid == 84532) {
            // Base Sepolia
            lzEndpoint = LZ_ENDPOINT_BASE_SEPOLIA;
            networkName = "BASE_SEPOLIA";
        } else {
            revert("Unsupported network");
        }

        vm.startBroadcast(deployerPrivateKey);

        console.log("==================================================");
        console.log("Deploying ZKK OFT Token");
        console.log("==================================================");
        console.log("Network:", networkName);
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("LayerZero Endpoint:", lzEndpoint);
        console.log("==================================================");

        // Deploy ZKK
        ZKK zkk = new ZKK(
            "ZakoKen",          // name
            "ZKK",              // symbol
            lzEndpoint,         // LayerZero endpoint
            deployer,           // owner
            DEFAULT_PROJECT_ID  // projectId
        );

        console.log("\nZKK OFT deployed to:", address(zkk));
        console.log("Name:", zkk.name());
        console.log("Symbol:", zkk.symbol());
        console.log("Decimals:", zkk.decimals());
        console.log("Project ID:", vm.toString(zkk.projectId()));
        console.log("Owner:", zkk.owner());

        console.log("\n==================================================");
        console.log("Deployment completed!");
        console.log("==================================================");
        console.log("\nAdd to .env:");
        console.log(string.concat("ZKK_OFT_", networkName, "="), address(zkk));
        console.log("\nNext steps:");
        console.log("1. Deploy on other chain (if needed)");
        console.log("2. Run: forge script script/ConfigureLayerZero.s.sol --rpc-url sepolia --broadcast");
        console.log("==================================================");

        vm.stopBroadcast();
    }
}
