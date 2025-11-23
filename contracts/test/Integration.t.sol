// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ZKK.sol";
import "../src/FixedExchange.sol";
import "../src/MockUSDC.sol";
import "./MockLZEndpoint.sol";

/**
 * @title Integration Tests
 * @notice End-to-end integration tests for ZakoKen protocol
 */
contract IntegrationTest is Test {
    ZKK public zkk;
    FixedExchange public exchange;
    MockUSDC public usdc;
    MockLZEndpoint public lzEndpoint;

    address public projectOwner;
    address public alice;
    address public bob;
    bytes32 public projectId;

    function setUp() public {
        projectOwner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        projectId = keccak256("zakoken-project");

        // Deploy all contracts
        lzEndpoint = new MockLZEndpoint();
        usdc = new MockUSDC();
        zkk = new ZKK("ZakoKen", "ZKK", address(lzEndpoint), projectOwner, projectId);
        exchange = new FixedExchange(
            address(zkk),
            address(usdc)
        );
    }

    // ============ Full Lifecycle Test ============

    function test_FullLifecycle() public {
        // 1. Project owner deposits USDC collateral
        uint256 initialCollateral = 100_000 * 10 ** 6; // 100k USDC
        usdc.approve(address(exchange), initialCollateral);
        exchange.depositCollateral(initialCollateral);

        assertEq(
            exchange.getAvailableCollateral(),
            initialCollateral,
            "Collateral not deposited"
        );

        // 2. Simulate off-chain transaction and mint ZKK to Alice
        uint256 aliceContribution = 1000 ether; // 1000 ZKK worth
        bytes32 aliceTxHash = keccak256("alice-github-pr-123");

        zkk.mintWithCompose(alice, aliceContribution, aliceTxHash, projectId);

        assertEq(
            zkk.balanceOf(alice),
            aliceContribution,
            "Alice didn't receive ZKK"
        );

        // 3. Simulate another contribution from Bob
        uint256 bobContribution = 500 ether; // 500 ZKK worth
        bytes32 bobTxHash = keccak256("bob-github-issue-456");

        zkk.mintWithCompose(bob, bobContribution, bobTxHash, projectId);

        assertEq(
            zkk.balanceOf(bob),
            bobContribution,
            "Bob didn't receive ZKK"
        );

        // 4. Alice redeems half her tokens for USDC
        uint256 aliceRedeemAmount = 500 ether;
        uint256 expectedUSDC = 500 * 10 ** 6; // 500 USDC

        vm.startPrank(alice);
        zkk.approve(address(exchange), aliceRedeemAmount);

        uint256 aliceUsdcBefore = usdc.balanceOf(alice);
        exchange.redeem(aliceRedeemAmount);
        uint256 aliceUsdcAfter = usdc.balanceOf(alice);

        assertEq(
            aliceUsdcAfter - aliceUsdcBefore,
            expectedUSDC,
            "Alice didn't receive correct USDC"
        );
        assertEq(
            zkk.balanceOf(alice),
            aliceContribution - aliceRedeemAmount,
            "Alice ZKK balance incorrect"
        );
        vm.stopPrank();

        // 5. Bob transfers some ZKK to Alice
        uint256 transferAmount = 100 ether;

        vm.prank(bob);
        zkk.transfer(alice, transferAmount);

        assertEq(
            zkk.balanceOf(bob),
            bobContribution - transferAmount,
            "Bob balance after transfer incorrect"
        );
        assertEq(
            zkk.balanceOf(alice),
            aliceContribution - aliceRedeemAmount + transferAmount,
            "Alice balance after receive incorrect"
        );

        // 6. Verify total supply (accounting for greed model)
        // Total supply should be >= expected due to greed penalties
        uint256 expectedMinSupply = aliceContribution +
            bobContribution -
            aliceRedeemAmount;
        assertGe(
            zkk.totalSupply(),
            expectedMinSupply,
            "Total supply should be at least the base amount"
        );

        // 7. Verify exchange collateral
        uint256 expectedCollateral = initialCollateral - expectedUSDC;
        assertEq(
            exchange.getAvailableCollateral(),
            expectedCollateral,
            "Exchange collateral incorrect"
        );
    }

    // ============ Greed Model Impact Test ============

    function test_GreedModelImpact() public {
        // Setup collateral
        uint256 collateral = 100_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        // Scenario: Alice makes rapid contributions
        uint256 amount = 100 ether;

        // First contribution - base rate
        zkk.mintWithCompose(alice, amount, keccak256("tx-1"), projectId);
        uint256 firstBalance = zkk.balanceOf(alice);
        assertEq(firstBalance, amount, "First mint should be 1x");

        // Second contribution immediately - rapid penalty applies
        zkk.mintWithCompose(alice, amount, keccak256("tx-2"), projectId);
        uint256 secondBalance = zkk.balanceOf(alice);
        assertGt(
            secondBalance - firstBalance,
            amount,
            "Second mint should have penalty"
        );

        // Wait 1 hour
        vm.warp(block.timestamp + 1 hours);

        // Third contribution after delay - no rapid penalty
        zkk.mintWithCompose(alice, amount, keccak256("tx-3"), projectId);
        uint256 thirdBalance = zkk.balanceOf(alice);
        assertEq(
            thirdBalance - secondBalance,
            amount,
            "Third mint should be 1x"
        );
    }

    // ============ Emergency Scenarios ============

    function test_EmergencyPause() public {
        // Setup
        uint256 collateral = 100_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        zkk.mintWithCompose(alice, 1000 ether, keccak256("tx-1"), projectId);

        // Emergency: Pause exchange
        exchange.pause();
        assertTrue(exchange.paused(), "Exchange should be paused");

        // Alice tries to redeem - should fail
        vm.startPrank(alice);
        zkk.approve(address(exchange), 500 ether);

        vm.expectRevert();
        exchange.redeem(500 ether);
        vm.stopPrank();

        // Unpause and retry
        exchange.unpause();
        assertFalse(exchange.paused(), "Exchange should be unpaused");

        vm.startPrank(alice);
        exchange.redeem(500 ether);
        assertGt(usdc.balanceOf(alice), 0, "Redemption should work after unpause");
        vm.stopPrank();
    }

    function test_CollateralManagement() public {
        uint256 initialDeposit = 50_000 * 10 ** 6;
        uint256 additionalDeposit = 50_000 * 10 ** 6;

        // Initial deposit
        usdc.approve(address(exchange), initialDeposit);
        exchange.depositCollateral(initialDeposit);

        // Mint tokens
        zkk.mintWithCompose(alice, 1000 ether, keccak256("tx-1"), projectId);

        // Additional deposit
        usdc.approve(address(exchange), additionalDeposit);
        exchange.depositCollateral(additionalDeposit);

        assertEq(
            exchange.getAvailableCollateral(),
            initialDeposit + additionalDeposit,
            "Total collateral incorrect"
        );

        // Partial withdrawal
        uint256 withdrawAmount = 30_000 * 10 ** 6;
        exchange.withdrawCollateral(withdrawAmount, projectOwner);

        assertEq(
            exchange.getAvailableCollateral(),
            initialDeposit + additionalDeposit - withdrawAmount,
            "Collateral after withdrawal incorrect"
        );
    }

    // ============ Multi-User Scenarios ============

    function test_MultiUserRedemptions() public {
        // Setup
        uint256 collateral = 100_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        // Mint to multiple users
        address[] memory users = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            users[i] = makeAddr(string(abi.encodePacked("user", i)));
            zkk.mintWithCompose(
                users[i],
                100 ether,
                keccak256(abi.encode(i)),
                projectId
            );
        }

        // All users redeem
        for (uint256 i = 0; i < 5; i++) {
            vm.startPrank(users[i]);
            uint256 balance = zkk.balanceOf(users[i]);
            zkk.approve(address(exchange), balance);
            exchange.redeem(balance);

            assertGt(
                usdc.balanceOf(users[i]),
                0,
                "User should receive USDC"
            );
            assertEq(zkk.balanceOf(users[i]), 0, "User ZKK should be 0");
            vm.stopPrank();
        }

        // Verify total redemptions
        assertEq(
            exchange.totalRedemptions(),
            500 ether,
            "Total redemptions incorrect"
        );
    }

    // ============ Exchange Rate Tests ============

    function test_DynamicExchangeRate() public {
        // Setup
        uint256 collateral = 100_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        zkk.mintWithCompose(alice, 1000 ether, keccak256("tx-1"), projectId);

        // Redeem at 1:1 rate
        vm.startPrank(alice);
        zkk.approve(address(exchange), 100 ether);
        exchange.redeem(100 ether);
        uint256 firstRedemption = usdc.balanceOf(alice);
        assertEq(firstRedemption, 100 * 10 ** 6, "First redemption at 1:1");
        vm.stopPrank();

        // Change rate to 0.98:1
        exchange.setExchangeRate(9800);

        // Redeem at new rate
        vm.startPrank(alice);
        zkk.approve(address(exchange), 100 ether);
        exchange.redeem(100 ether);
        uint256 secondRedemption = usdc.balanceOf(alice) - firstRedemption;
        assertEq(secondRedemption, 98 * 10 ** 6, "Second redemption at 0.98:1");
        vm.stopPrank();
    }

    // ============ Stress Tests ============

    function test_LargeScaleOperations() public {
        // Setup large collateral
        uint256 collateral = 10_000_000 * 10 ** 6; // 10M USDC
        usdc.mint(projectOwner, collateral);
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        // Mint to many users
        uint256 numUsers = 100;
        for (uint256 i = 0; i < numUsers; i++) {
            address user = makeAddr(string(abi.encodePacked("user", i)));
            zkk.mintWithCompose(
                user,
                1000 ether,
                keccak256(abi.encode(i)),
                projectId
            );
        }

        // Verify total supply
        assertEq(
            zkk.totalSupply(),
            1000 ether * numUsers,
            "Total supply incorrect"
        );

        // Spot check redemptions
        for (uint256 i = 0; i < 10; i++) {
            address user = makeAddr(string(abi.encodePacked("user", i)));
            vm.startPrank(user);
            zkk.approve(address(exchange), 500 ether);
            exchange.redeem(500 ether);
            vm.stopPrank();
        }
    }

    // ============ Edge Cases ============

    function test_ZeroBalanceOperations() public {
        // Try to redeem with no tokens
        vm.expectRevert();
        vm.prank(alice);
        exchange.redeem(100 ether);
    }

    function test_FullDepletionAndRefill() public {
        // Setup
        uint256 collateral = 1000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        zkk.mintWithCompose(alice, 1000 ether, keccak256("tx-1"), projectId);

        // Deplete all collateral
        vm.startPrank(alice);
        zkk.approve(address(exchange), 1000 ether);
        exchange.redeem(1000 ether);
        vm.stopPrank();

        assertEq(
            exchange.getAvailableCollateral(),
            0,
            "Collateral should be 0"
        );

        // Refill collateral
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        assertEq(
            exchange.getAvailableCollateral(),
            collateral,
            "Collateral should be refilled"
        );
    }

    function test_ProjectOwnerOperations() public {
        // Mint USDC to exchange
        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        // Mint ZKK
        zkk.mintWithCompose(alice, 1000 ether, keccak256("tx-1"), projectId);

        // Owner can pause
        exchange.pause();
        assertTrue(exchange.paused());

        // Owner can set rate
        exchange.setExchangeRate(9900);
        assertEq(exchange.exchangeRate(), 9900);

        // Owner can withdraw collateral
        uint256 withdrawAmount = 5000 * 10 ** 6;
        uint256 ownerBalanceBefore = usdc.balanceOf(projectOwner);
        exchange.withdrawCollateral(withdrawAmount, projectOwner);
        uint256 ownerBalanceAfter = usdc.balanceOf(projectOwner);

        assertEq(
            ownerBalanceAfter - ownerBalanceBefore,
            withdrawAmount,
            "Owner didn't receive withdrawal"
        );
    }
}
