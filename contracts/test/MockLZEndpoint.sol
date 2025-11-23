// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockLZEndpoint
 * @notice Mock LayerZero Endpoint for testing
 */
contract MockLZEndpoint {
    function send(
        uint32,
        bytes calldata,
        bytes calldata,
        address payable,
        address,
        bytes calldata
    ) external payable {}

    function setDelegate(address) external {}

    function eid() external pure returns (uint32) {
        return 40161; // Sepolia EID
    }
}
