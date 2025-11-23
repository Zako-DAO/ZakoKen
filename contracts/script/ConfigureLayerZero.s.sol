// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ZKK.sol";

/**
 * @title ConfigureLayerZero
 * @notice Configure LayerZero peers for cross-chain communication
 * @dev Usage:
 *   1. Set ZKK_OFT_SEPOLIA and ZKK_OFT_BASE_SEPOLIA in .env
 *   2. Run on Sepolia: forge script script/ConfigureLayerZero.s.sol:ConfigureLayerZero --rpc-url sepolia --broadcast
 *   3. Run on Base Sepolia: forge script script/ConfigureLayerZero.s.sol:ConfigureLayerZero --rpc-url baseSepolia --broadcast
 */
contract ConfigureLayerZero is Script {
    // LayerZero Endpoint IDs (EIDs)
    uint32 constant LZ_EID_SEPOLIA = 40161;
    uint32 constant LZ_EID_BASE_SEPOLIA = 40245;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Load deployed addresses from environment
        address sepoliaZKK = vm.envAddress("ZKK_OFT_SEPOLIA");
        address baseSepoliaZKK = vm.envAddress("ZKK_OFT_BASE_SEPOLIA");

        console.log("==================================================");
        console.log("Configuring LayerZero Peers");
        console.log("==================================================");
        console.log("Sepolia ZKK:", sepoliaZKK);
        console.log("Base Sepolia ZKK:", baseSepoliaZKK);
        console.log("==================================================");

        if (block.chainid == 11155111) {
            // Configure on Sepolia
            configureSepoliaPeer(deployerPrivateKey, sepoliaZKK, baseSepoliaZKK);
        } else if (block.chainid == 84532) {
            // Configure on Base Sepolia
            configureBaseSepoliaPeer(deployerPrivateKey, baseSepoliaZKK, sepoliaZKK);
        } else {
            revert("Unsupported network");
        }
    }

    function configureSepoliaPeer(
        uint256 privateKey,
        address sepoliaZKK,
        address baseSepoliaZKK
    ) internal {
        vm.startBroadcast(privateKey);

        console.log("\nConfiguring Sepolia -> Base Sepolia");
        console.log("Remote Chain EID:", LZ_EID_BASE_SEPOLIA);
        console.log("Remote ZKK Address:", baseSepoliaZKK);

        ZKK zkk = ZKK(sepoliaZKK);

        // Encode peer address (convert address to bytes32)
        bytes32 peerAddress = bytes32(uint256(uint160(baseSepoliaZKK)));

        console.log("Encoded Peer:", vm.toString(peerAddress));

        // Set peer
        zkk.setPeer(LZ_EID_BASE_SEPOLIA, peerAddress);

        console.log("Peer set successfully!");

        // Verify
        bytes32 storedPeer = zkk.peers(LZ_EID_BASE_SEPOLIA);
        console.log("Stored Peer:", vm.toString(storedPeer));
        console.log("Match:", storedPeer == peerAddress ? "YES" : "NO");

        console.log("\n==================================================");
        console.log("Sepolia configuration completed!");
        console.log("==================================================");

        vm.stopBroadcast();
    }

    function configureBaseSepoliaPeer(
        uint256 privateKey,
        address baseSepoliaZKK,
        address sepoliaZKK
    ) internal {
        vm.startBroadcast(privateKey);

        console.log("\nConfiguring Base Sepolia -> Sepolia");
        console.log("Remote Chain EID:", LZ_EID_SEPOLIA);
        console.log("Remote ZKK Address:", sepoliaZKK);

        ZKK zkk = ZKK(baseSepoliaZKK);

        // Encode peer address (convert address to bytes32)
        bytes32 peerAddress = bytes32(uint256(uint160(sepoliaZKK)));

        console.log("Encoded Peer:", vm.toString(peerAddress));

        // Set peer
        zkk.setPeer(LZ_EID_SEPOLIA, peerAddress);

        console.log("Peer set successfully!");

        // Verify
        bytes32 storedPeer = zkk.peers(LZ_EID_SEPOLIA);
        console.log("Stored Peer:", vm.toString(storedPeer));
        console.log("Match:", storedPeer == peerAddress ? "YES" : "NO");

        console.log("\n==================================================");
        console.log("Base Sepolia configuration completed!");
        console.log("==================================================");

        vm.stopBroadcast();
    }
}
