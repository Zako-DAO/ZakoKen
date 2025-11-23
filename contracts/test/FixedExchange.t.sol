// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FixedExchange.sol";
import "../src/ZKK.sol";
import "../src/MockUSDC.sol";
import "./MockLZEndpoint.sol";

/**
 * @title FixedExchange Tests
 * @notice Solidity tests for FixedExchange contract
 */
contract FixedExchangeTest is Test {
    FixedExchange public exchange;
    ZKK public zkk;
    MockUSDC public usdc;
    MockLZEndpoint public lzEndpoint;

    address public owner;
    address public user1;
    address public user2;
    bytes32 public projectId;

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

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        projectId = keccak256("test-project");

        // Deploy contracts
        lzEndpoint = new MockLZEndpoint();
        usdc = new MockUSDC();
        zkk = new ZKK("ZakoKen", "ZKK", address(lzEndpoint), owner, projectId);
        exchange = new FixedExchange(address(zkk), address(usdc));

        // Setup initial state
        _setupInitialBalances();
    }

    function _setupInitialBalances() internal {
        // Mint USDC to users and owner
        usdc.mint(owner, 1_000_000 * 10 ** 6); // 1M USDC
        usdc.mint(user1, 100_000 * 10 ** 6); // 100k USDC
        usdc.mint(user2, 100_000 * 10 ** 6); // 100k USDC

        // Mint ZKK to users
        zkk.mintWithCompose(user1, 1000 ether, keccak256("tx-1"), projectId);
        zkk.mintWithCompose(user2, 1000 ether, keccak256("tx-2"), projectId);
    }

    // ============ Deployment Tests ============

    function test_Deployment() public view {
        assertEq(address(exchange.zkk()), address(zkk));
        assertEq(address(exchange.usdc()), address(usdc));
        assertEq(exchange.exchangeRate(), 10000);
        assertEq(exchange.BASIS_POINTS(), 10000);
    }

    function test_RevertIf_Deployment_ZeroZKK() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        new FixedExchange(address(0), address(usdc));
    }

    function test_RevertIf_Deployment_ZeroUSDC() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        new FixedExchange(address(zkk), address(0));
    }

    // ============ Collateral Management Tests ============

    function test_DepositCollateral() public {
        uint256 amount = 10_000 * 10 ** 6; // 10k USDC

        usdc.approve(address(exchange), amount);
        exchange.depositCollateral(amount);

        assertEq(exchange.totalCollateral(), amount);
        assertEq(exchange.getAvailableCollateral(), amount);
    }

    function test_DepositCollateral_EmitsEvent() public {
        uint256 amount = 10_000 * 10 ** 6;

        usdc.approve(address(exchange), amount);

        vm.expectEmit(true, false, false, false);
        emit CollateralDeposited(owner, amount, 0);

        exchange.depositCollateral(amount);
    }

    function test_DepositCollateral_Multiple() public {
        uint256 amount1 = 10_000 * 10 ** 6;
        uint256 amount2 = 5_000 * 10 ** 6;

        usdc.approve(address(exchange), amount1 + amount2);

        exchange.depositCollateral(amount1);
        exchange.depositCollateral(amount2);

        assertEq(exchange.totalCollateral(), amount1 + amount2);
    }

    function test_RevertIf_DepositCollateral_ZeroAmount() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        exchange.depositCollateral(0);
    }

    function test_RevertIf_DepositCollateral_InsufficientApproval() public {
        uint256 amount = 10_000 * 10 ** 6;
        vm.expectRevert();
        exchange.depositCollateral(amount);
    }

    function test_WithdrawCollateral() public {
        uint256 depositAmount = 10_000 * 10 ** 6;
        uint256 withdrawAmount = 5_000 * 10 ** 6;

        usdc.approve(address(exchange), depositAmount);
        exchange.depositCollateral(depositAmount);

        uint256 balanceBefore = usdc.balanceOf(owner);
        exchange.withdrawCollateral(withdrawAmount, owner);
        uint256 balanceAfter = usdc.balanceOf(owner);

        assertEq(balanceAfter - balanceBefore, withdrawAmount);
        assertEq(exchange.getAvailableCollateral(), depositAmount - withdrawAmount);
    }

    function test_WithdrawCollateral_EmitsEvent() public {
        uint256 amount = 10_000 * 10 ** 6;

        usdc.approve(address(exchange), amount);
        exchange.depositCollateral(amount);

        vm.expectEmit(true, false, false, false);
        emit CollateralWithdrawn(owner, amount, 0);

        exchange.withdrawCollateral(amount, owner);
    }

    function test_RevertIf_WithdrawCollateral_NotOwner() public {
        uint256 amount = 10_000 * 10 ** 6;

        usdc.approve(address(exchange), amount);
        exchange.depositCollateral(amount);

        vm.prank(user1);
        vm.expectRevert();
        exchange.withdrawCollateral(amount, user1);
    }

    function test_RevertIf_WithdrawCollateral_InsufficientCollateral() public {
        uint256 amount = 10_000 * 10 ** 6;

        usdc.approve(address(exchange), amount);
        exchange.depositCollateral(amount);

        vm.expectRevert(abi.encodeWithSignature("InsufficientCollateral()"));
        exchange.withdrawCollateral(amount * 2, owner);
    }

    // ============ Redemption Tests ============

    function test_Redeem() public {
        // Setup: Deposit collateral
        uint256 collateral = 10_000 * 10 ** 6; // 10k USDC
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        // Redeem 100 ZKK for USDC
        uint256 zkkAmount = 100 ether;
        uint256 expectedUsdc = 100 * 10 ** 6; // 100 USDC (6 decimals)

        vm.startPrank(user1);
        zkk.approve(address(exchange), zkkAmount);

        uint256 usdcBefore = usdc.balanceOf(user1);
        exchange.redeem(zkkAmount);
        uint256 usdcAfter = usdc.balanceOf(user1);

        assertEq(usdcAfter - usdcBefore, expectedUsdc);
        assertEq(zkk.balanceOf(address(exchange)), zkkAmount);
        vm.stopPrank();
    }

    function test_Redeem_EmitsEvent() public {
        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        uint256 zkkAmount = 100 ether;

        vm.startPrank(user1);
        zkk.approve(address(exchange), zkkAmount);

        vm.expectEmit(true, false, false, false);
        emit Redeemed(user1, zkkAmount, 0, 0);

        exchange.redeem(zkkAmount);
        vm.stopPrank();
    }

    function test_Redeem_UpdatesTotalRedemptions() public {
        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        uint256 zkkAmount = 100 ether;

        vm.startPrank(user1);
        zkk.approve(address(exchange), zkkAmount);
        exchange.redeem(zkkAmount);
        vm.stopPrank();

        assertEq(exchange.totalRedemptions(), zkkAmount);
    }

    function test_Redeem_MultipleRedemptions() public {
        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        uint256 zkkAmount1 = 100 ether;
        uint256 zkkAmount2 = 50 ether;

        // User1 redeems
        vm.startPrank(user1);
        zkk.approve(address(exchange), zkkAmount1);
        exchange.redeem(zkkAmount1);
        vm.stopPrank();

        // User2 redeems
        vm.startPrank(user2);
        zkk.approve(address(exchange), zkkAmount2);
        exchange.redeem(zkkAmount2);
        vm.stopPrank();

        assertEq(exchange.totalRedemptions(), zkkAmount1 + zkkAmount2);
    }

    function test_RevertIf_Redeem_ZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        exchange.redeem(0);
    }

    function test_RevertIf_Redeem_InsufficientCollateral() public {
        // No collateral deposited
        uint256 zkkAmount = 100 ether;

        vm.startPrank(user1);
        zkk.approve(address(exchange), zkkAmount);
        vm.expectRevert(abi.encodeWithSignature("InsufficientCollateral()"));
        exchange.redeem(zkkAmount);
        vm.stopPrank();
    }

    function test_RevertIf_Redeem_InsufficientZKKApproval() public {
        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        vm.prank(user1);
        vm.expectRevert();
        exchange.redeem(100 ether);
    }

    // ============ View Function Tests ============

    function test_GetOutputAmount() public view {
        uint256 zkkAmount = 100 ether;
        uint256 expectedUsdc = 100 * 10 ** 6;

        uint256 output = exchange.getOutputAmount(zkkAmount);
        assertEq(output, expectedUsdc);
    }

    function test_CanRedeem_True() public {
        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        assertTrue(exchange.canRedeem(100 ether));
    }

    function test_CanRedeem_False_InsufficientCollateral() public view {
        assertFalse(exchange.canRedeem(100 ether));
    }

    function test_CanRedeem_False_ZeroAmount() public view {
        assertFalse(exchange.canRedeem(0));
    }

    // ============ Pause Tests ============

    function test_Pause() public {
        exchange.pause();
        assertTrue(exchange.paused());
    }

    function test_Unpause() public {
        exchange.pause();
        exchange.unpause();
        assertFalse(exchange.paused());
    }

    function test_RevertIf_Pause_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        exchange.pause();
    }

    function test_RevertIf_Redeem_WhenPaused() public {
        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        exchange.pause();

        vm.startPrank(user1);
        zkk.approve(address(exchange), 100 ether);
        vm.expectRevert();
        exchange.redeem(100 ether);
        vm.stopPrank();
    }

    function test_RevertIf_DepositCollateral_WhenPaused() public {
        exchange.pause();

        uint256 amount = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), amount);
        vm.expectRevert();
        exchange.depositCollateral(amount);
    }

    // ============ Exchange Rate Tests ============

    function test_SetExchangeRate() public {
        uint256 newRate = 9900; // 0.99:1
        exchange.setExchangeRate(newRate);
        assertEq(exchange.exchangeRate(), newRate);
    }

    function test_RevertIf_SetExchangeRate_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        exchange.setExchangeRate(9900);
    }

    function test_RevertIf_SetExchangeRate_ZeroRate() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        exchange.setExchangeRate(0);
    }

    function test_RedeemWithCustomRate() public {
        // Set rate to 0.98:1
        exchange.setExchangeRate(9800);

        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        uint256 zkkAmount = 100 ether;
        uint256 expectedUsdc = 98 * 10 ** 6; // 98 USDC due to 0.98 rate

        vm.startPrank(user1);
        zkk.approve(address(exchange), zkkAmount);

        uint256 usdcBefore = usdc.balanceOf(user1);
        exchange.redeem(zkkAmount);
        uint256 usdcAfter = usdc.balanceOf(user1);

        assertEq(usdcAfter - usdcBefore, expectedUsdc);
        vm.stopPrank();
    }

    // ============ Fuzz Tests ============

    function testFuzz_DepositCollateral(uint256 amount) public {
        vm.assume(amount > 0 && amount < 1_000_000_000 * 10 ** 6);

        usdc.mint(owner, amount);
        usdc.approve(address(exchange), amount);
        exchange.depositCollateral(amount);

        assertEq(exchange.getAvailableCollateral(), amount);
    }

    function testFuzz_Redeem(uint96 zkkAmount) public {
        vm.assume(zkkAmount > 0);

        // Setup collateral
        uint256 collateral = 1_000_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        // Mint ZKK to user
        zkk.mintWithCompose(
            user1,
            uint256(zkkAmount),
            keccak256(abi.encode(zkkAmount)),
            projectId
        );

        uint256 userBalance = zkk.balanceOf(user1);

        vm.startPrank(user1);
        zkk.approve(address(exchange), userBalance);

        if (exchange.canRedeem(userBalance)) {
            exchange.redeem(userBalance);
            assertGt(usdc.balanceOf(user1), 0);
        }
        vm.stopPrank();
    }

    // ============ Edge Cases ============

    function test_RedeemExactCollateral() public {
        // Deposit exact amount needed
        uint256 zkkAmount = 100 ether;
        uint256 exactCollateral = 100 * 10 ** 6;

        usdc.approve(address(exchange), exactCollateral);
        exchange.depositCollateral(exactCollateral);

        vm.startPrank(user1);
        zkk.approve(address(exchange), zkkAmount);
        exchange.redeem(zkkAmount);
        vm.stopPrank();

        assertEq(exchange.getAvailableCollateral(), 0);
    }

    function test_RedeemSmallAmount() public {
        uint256 collateral = 10_000 * 10 ** 6;
        usdc.approve(address(exchange), collateral);
        exchange.depositCollateral(collateral);

        uint256 zkkAmount = 1 ether; // 1 ZKK
        uint256 expectedUsdc = 1 * 10 ** 6; // 1 USDC

        vm.startPrank(user1);
        zkk.approve(address(exchange), zkkAmount);

        uint256 usdcBefore = usdc.balanceOf(user1);
        exchange.redeem(zkkAmount);
        uint256 usdcAfter = usdc.balanceOf(user1);

        assertEq(usdcAfter - usdcBefore, expectedUsdc);
        vm.stopPrank();
    }
}
