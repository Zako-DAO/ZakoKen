import { ethers } from "hardhat";
import { loadDeployment, waitForTx, section } from "./utils/helpers.js";

/**
 * Setup complete demo environment:
 * 1. Mint test USDC
 * 2. Deposit USDC collateral to FixedExchange
 * 3. Mint test ZKK tokens
 *
 * Usage: pnpm hardhat run scripts/setup-demo.ts --network sepolia
 */

const DEMO_AMOUNTS = {
  USDC_MINT: 100000, // 100k USDC
  USDC_COLLATERAL: 50000, // 50k USDC collateral
  ZKK_MINT: 1000, // 1000 ZKK tokens
};

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? process.env.HARDHAT_NETWORK || "hardhat" : network.name;

  section("Demo Environment Setup");
  console.log("Network:", networkName);
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

  // Load deployments
  const usdcDeployment = loadDeployment("usdc", networkName);
  const zkkDeployment = loadDeployment("zkk", networkName);
  const exchangeDeployment = loadDeployment("exchange", networkName);

  const usdcAddress = usdcDeployment.contracts.MockUSDC.address;
  const zkkAddress = zkkDeployment.contracts.ZKK.address;
  const exchangeAddress = exchangeDeployment.contracts.FixedExchange.address;

  console.log("\n📋 Contract Addresses:");
  console.log("  USDC:", usdcAddress);
  console.log("  ZKK:", zkkAddress);
  console.log("  FixedExchange:", exchangeAddress);

  // Get contract instances
  const usdc = await ethers.getContractAt("MockUSDC", usdcAddress);
  const zkk = await ethers.getContractAt("ZKK", zkkAddress);
  const exchange = await ethers.getContractAt("FixedExchange", exchangeAddress);

  // Step 1: Mint USDC
  section("Step 1: Minting Test USDC");
  const usdcAmount = BigInt(DEMO_AMOUNTS.USDC_MINT) * 10n ** 6n; // 6 decimals
  console.log(`Minting ${DEMO_AMOUNTS.USDC_MINT} USDC...`);
  const mintTx = await usdc.mint(deployer.address, usdcAmount);
  await waitForTx(mintTx, "Minting USDC");

  const usdcBalance = await usdc.balanceOf(deployer.address);
  console.log("✅ USDC Balance:", ethers.formatUnits(usdcBalance, 6), "USDC");

  // Step 2: Deposit USDC collateral
  section("Step 2: Depositing USDC Collateral");
  const collateralAmount = BigInt(DEMO_AMOUNTS.USDC_COLLATERAL) * 10n ** 6n;
  console.log(`Depositing ${DEMO_AMOUNTS.USDC_COLLATERAL} USDC to FixedExchange...`);

  console.log("  Approving USDC...");
  const approveTx = await usdc.approve(exchangeAddress, collateralAmount);
  await waitForTx(approveTx, "Approving USDC");

  console.log("  Depositing collateral...");
  const depositTx = await exchange.depositCollateral(collateralAmount);
  await waitForTx(depositTx, "Depositing collateral");

  const availableCollateral = await exchange.getAvailableCollateral();
  console.log("✅ Exchange Collateral:", ethers.formatUnits(availableCollateral, 6), "USDC");

  // Step 3: Mint ZKK tokens
  section("Step 3: Minting Test ZKK Tokens");
  const zkkAmount = BigInt(DEMO_AMOUNTS.ZKK_MINT) * 10n ** 18n; // 18 decimals
  const txHash = ethers.id("demo-tx-" + Date.now());
  const projectId = await zkk.projectId();

  console.log(`Minting ${DEMO_AMOUNTS.ZKK_MINT} ZKK tokens...`);
  console.log("  Transaction Hash:", txHash);
  console.log("  Project ID:", projectId);

  const mintZKKTx = await zkk.mintWithCompose(
    deployer.address,
    zkkAmount,
    txHash,
    projectId
  );
  await waitForTx(mintZKKTx, "Minting ZKK");

  const zkkBalance = await zkk.balanceOf(deployer.address);
  console.log("✅ ZKK Balance:", ethers.formatEther(zkkBalance), "ZKK");

  // Summary
  section("✅ Demo Setup Complete!");
  console.log("\n📊 Summary:");
  console.log("  USDC Balance:", ethers.formatUnits(usdcBalance, 6), "USDC");
  console.log("  ZKK Balance:", ethers.formatEther(zkkBalance), "ZKK");
  console.log("  Exchange Collateral:", ethers.formatUnits(availableCollateral, 6), "USDC");

  console.log("\n🎮 Next Steps:");
  console.log("1. Test redemption:");
  console.log(`   - Approve ZKK: zkk.approve("${exchangeAddress}", amount)`);
  console.log(`   - Redeem: exchange.redeem(amount)`);
  console.log("\n2. Test cross-chain transfer:");
  console.log("   - Deploy on Base Sepolia");
  console.log("   - Configure LayerZero peers");
  console.log("   - Send tokens cross-chain");
  console.log("\n3. Launch frontend:");
  console.log("   - cd ../frontend");
  console.log("   - pnpm install && pnpm dev");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
