// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ZKK.sol";
import "./MockLZEndpoint.sol";

/**
 * @title ZKK Token Tests
 * @notice Solidity tests for ZKK OFT token
 */
contract ZKKTest is Test {
    ZKK public zkk;
    MockLZEndpoint public lzEndpoint;
    address public owner;
    address public user1;
    address public user2;
    bytes32 public projectId;

    event TokensMinted(
        address indexed recipient,
        uint256 amount,
        bytes32 indexed txHash,
        bytes32 indexed projectId,
        uint256 greedIndex,
        uint256 timestamp
    );

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        projectId = keccak256("test-project");

        // Deploy mock LayerZero endpoint
        lzEndpoint = new MockLZEndpoint();

        zkk = new ZKK("ZakoKen", "ZKK", address(lzEndpoint), owner, projectId);
    }

    // ============ Deployment Tests ============

    function test_Deployment() public view {
        assertEq(zkk.name(), "ZakoKen");
        assertEq(zkk.symbol(), "ZKK");
        assertEq(zkk.decimals(), 18);
        assertEq(zkk.owner(), owner);
        assertEq(zkk.projectId(), projectId);
    }

    function test_InitialSupply() public view {
        assertEq(zkk.totalSupply(), 0);
    }

    // ============ Minting Tests ============

    function test_MintWithCompose() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");

        zkk.mintWithCompose(user1, amount, txHash, projectId);

        assertEq(zkk.balanceOf(user1), amount);
        assertEq(zkk.totalSupply(), amount);
    }

    function test_MintWithCompose_EmitsEvent() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");

        vm.expectEmit(true, true, true, false);
        emit TokensMinted(
            user1,
            amount,
            txHash,
            projectId,
            10000, // Base greed multiplier
            0 // Placeholder for timestamp
        );

        zkk.mintWithCompose(user1, amount, txHash, projectId);
    }

    function test_MintWithCompose_UpdatesLastMintTime() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");

        assertEq(zkk.lastMintTime(user1), 0);

        zkk.mintWithCompose(user1, amount, txHash, projectId);

        assertGt(zkk.lastMintTime(user1), 0);
    }

    function test_MintWithCompose_UpdatesTotalMinted() public {
        uint256 amount = 100 ether;
        bytes32 txHash1 = keccak256("tx-1");
        bytes32 txHash2 = keccak256("tx-2");

        zkk.mintWithCompose(user1, amount, txHash1, projectId);
        zkk.mintWithCompose(user1, amount, txHash2, projectId);

        assertGt(zkk.totalMinted(user1), amount * 2);
    }

    function test_RevertIf_MintWithCompose_ZeroAddress() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");

        vm.expectRevert(abi.encodeWithSignature("InvalidRecipient()"));
        zkk.mintWithCompose(address(0), amount, txHash, projectId);
    }

    function test_RevertIf_MintWithCompose_ZeroAmount() public {
        bytes32 txHash = keccak256("tx-1");

        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        zkk.mintWithCompose(user1, 0, txHash, projectId);
    }

    function test_RevertIf_MintWithCompose_WrongProjectId() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");
        bytes32 wrongProjectId = keccak256("wrong-project");

        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        zkk.mintWithCompose(user1, amount, txHash, wrongProjectId);
    }

    function test_RevertIf_MintWithCompose_NotOwner() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");

        vm.prank(user1);
        vm.expectRevert();
        zkk.mintWithCompose(user2, amount, txHash, projectId);
    }

    // ============ Greed Model Tests ============

    function test_GreedModel_BaseMultiplier() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");

        zkk.mintWithCompose(user1, amount, txHash, projectId);

        // First mint should have base multiplier (1x)
        assertEq(zkk.balanceOf(user1), amount);
    }

    function test_GreedModel_RapidMintingPenalty() public {
        uint256 amount = 100 ether;
        bytes32 txHash1 = keccak256("tx-1");
        bytes32 txHash2 = keccak256("tx-2");

        // First mint
        zkk.mintWithCompose(user1, amount, txHash1, projectId);
        uint256 balanceAfterFirst = zkk.balanceOf(user1);

        // Second mint immediately (< 1 hour)
        zkk.mintWithCompose(user1, amount, txHash2, projectId);
        uint256 balanceAfterSecond = zkk.balanceOf(user1);

        // Second mint should have penalty (> 1x multiplier)
        assertGt(balanceAfterSecond - balanceAfterFirst, amount);
    }

    function test_GreedModel_NoRapidMintingPenaltyAfterDelay() public {
        uint256 amount = 100 ether;
        bytes32 txHash1 = keccak256("tx-1");
        bytes32 txHash2 = keccak256("tx-2");

        // First mint
        zkk.mintWithCompose(user1, amount, txHash1, projectId);

        // Wait 1 hour
        vm.warp(block.timestamp + 1 hours);

        // Second mint after delay
        zkk.mintWithCompose(user1, amount, txHash2, projectId);

        // No rapid minting penalty
        assertEq(zkk.balanceOf(user1), amount * 2);
    }

    function test_GreedModel_LargeTransactionPenalty() public {
        uint256 largeAmount = 1001 ether; // > 1000 threshold
        bytes32 txHash = keccak256("tx-1");

        zkk.mintWithCompose(user1, largeAmount, txHash, projectId);

        // Should apply large transaction penalty (1.15x)
        assertGt(zkk.balanceOf(user1), largeAmount);
    }

    function test_GreedModel_LargeHolderPenalty() public {
        uint256 amount = 5001 ether; // First mint to exceed 10k threshold
        bytes32 txHash1 = keccak256("tx-1");
        bytes32 txHash2 = keccak256("tx-2");

        // First large mint (gets into large holder range after greed)
        zkk.mintWithCompose(user1, amount, txHash1, projectId);

        // Second mint to large holder
        zkk.mintWithCompose(user1, amount, txHash2, projectId);

        // Total should reflect penalties
        assertGt(zkk.totalMinted(user1), amount * 2);
    }

    // ============ Transfer Tests ============

    function test_Transfer() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");

        zkk.mintWithCompose(user1, amount, txHash, projectId);

        vm.prank(user1);
        zkk.transfer(user2, amount);

        assertEq(zkk.balanceOf(user1), 0);
        assertEq(zkk.balanceOf(user2), amount);
    }

    function test_Approve() public {
        uint256 amount = 100 ether;

        vm.prank(user1);
        zkk.approve(user2, amount);

        assertEq(zkk.allowance(user1, user2), amount);
    }

    function test_TransferFrom() public {
        uint256 amount = 100 ether;
        bytes32 txHash = keccak256("tx-1");

        zkk.mintWithCompose(user1, amount, txHash, projectId);

        vm.prank(user1);
        zkk.approve(user2, amount);

        vm.prank(user2);
        zkk.transferFrom(user1, user2, amount);

        assertEq(zkk.balanceOf(user1), 0);
        assertEq(zkk.balanceOf(user2), amount);
    }

    // ============ Fuzz Tests ============

    function testFuzz_MintWithCompose(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);
        bytes32 txHash = keccak256(abi.encode(amount));

        zkk.mintWithCompose(user1, amount, txHash, projectId);

        // Balance should be at least the amount (can be more due to greed)
        assertGe(zkk.balanceOf(user1), amount);
    }

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);
        bytes32 txHash = keccak256(abi.encode(amount));

        zkk.mintWithCompose(user1, amount, txHash, projectId);
        uint256 balance = zkk.balanceOf(user1);

        vm.prank(user1);
        zkk.transfer(user2, balance);

        assertEq(zkk.balanceOf(user1), 0);
        assertEq(zkk.balanceOf(user2), balance);
    }

    // ============ Edge Cases ============

    function test_MintToMultipleUsers() public {
        uint256 amount = 100 ether;
        bytes32 txHash1 = keccak256("tx-1");
        bytes32 txHash2 = keccak256("tx-2");

        zkk.mintWithCompose(user1, amount, txHash1, projectId);
        zkk.mintWithCompose(user2, amount, txHash2, projectId);

        assertEq(zkk.balanceOf(user1), amount);
        assertEq(zkk.balanceOf(user2), amount);
        assertEq(zkk.totalSupply(), amount * 2);
    }

    function test_GreedModel_MaxMultiplier() public {
        // Create scenario with max penalties:
        // 1. Large amount (> 1000) = +15%
        // 2. Rapid minting = +10%
        // 3. Large holder (> 10k) = +20%
        // Total = 1.45x, but capped at 2x

        uint256 largeAmount = 10001 ether;
        bytes32 txHash1 = keccak256("tx-1");
        bytes32 txHash2 = keccak256("tx-2");

        // First mint to become large holder
        zkk.mintWithCompose(user1, largeAmount, txHash1, projectId);

        // Second large mint immediately
        zkk.mintWithCompose(user1, largeAmount, txHash2, projectId);

        // Should be capped at 2x max multiplier
        uint256 totalMinted = zkk.totalMinted(user1);
        assertLe(totalMinted, largeAmount * 4); // 2x on each mint
    }
}
