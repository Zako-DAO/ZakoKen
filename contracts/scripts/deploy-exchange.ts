import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

/**
 * Deploy FixedExchange contract
 * Requires: ZKK and USDC already deployed
 * Usage: pnpm hardhat run scripts/deploy-exchange.ts --network sepolia
 */

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? process.env.HARDHAT_NETWORK || "hardhat" : network.name;

  console.log("=".repeat(50));
  console.log("Deploying FixedExchange");
  console.log("=".repeat(50));
  console.log("Network:", networkName);
  console.log("Chain ID:", network.chainId);
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");
  console.log("=".repeat(50));

  // Load deployment addresses
  const deploymentsDir = path.join(process.cwd(), "deployments");

  const zkkFile = path.join(deploymentsDir, `zkk-${networkName}.json`);
  const usdcFile = path.join(deploymentsDir, `usdc-${networkName}.json`);

  if (!fs.existsSync(zkkFile)) {
    throw new Error(`ZKK deployment not found. Please deploy ZKK first: pnpm hardhat run scripts/deploy-zkk.ts --network ${networkName}`);
  }
  if (!fs.existsSync(usdcFile)) {
    throw new Error(`USDC deployment not found. Please deploy MockUSDC first: pnpm hardhat run scripts/deploy-usdc.ts --network ${networkName}`);
  }

  const zkkDeployment = JSON.parse(fs.readFileSync(zkkFile, "utf8"));
  const usdcDeployment = JSON.parse(fs.readFileSync(usdcFile, "utf8"));

  const zkkAddress = zkkDeployment.contracts.ZKK.address;
  const usdcAddress = usdcDeployment.contracts.MockUSDC.address;

  console.log("\n📋 Prerequisites:");
  console.log("  ZKK Token:", zkkAddress);
  console.log("  USDC Token:", usdcAddress);

  // Deploy FixedExchange
  console.log("\n📝 Deploying FixedExchange...");
  const FixedExchange = await ethers.getContractFactory("FixedExchange");
  const exchange = await FixedExchange.deploy(
    zkkAddress,
    usdcAddress,
    deployer.address
  );
  await exchange.waitForDeployment();

  const exchangeAddress = await exchange.getAddress();
  console.log("✅ FixedExchange deployed to:", exchangeAddress);

  // Verify deployment
  const zkkToken = await exchange.zkk();
  const usdcToken = await exchange.usdc();
  const exchangeRate = await exchange.exchangeRate();
  const basisPoints = await exchange.BASIS_POINTS();

  console.log("\n📊 Exchange Details:");
  console.log("  ZKK Token:", zkkToken);
  console.log("  USDC Token:", usdcToken);
  console.log("  Exchange Rate:", `${exchangeRate}/${basisPoints} (1:1)`);
  console.log("  Owner:", deployer.address);

  // Optional: Deposit initial collateral
  console.log("\n💰 Would you like to deposit initial USDC collateral?");
  console.log("   (You can do this later manually)");

  // Save deployment info
  const deploymentInfo = {
    network: networkName,
    chainId: Number(network.chainId),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      FixedExchange: {
        address: exchangeAddress,
        zkkToken: zkkToken,
        usdcToken: usdcToken,
        exchangeRate: exchangeRate.toString(),
        basisPoints: basisPoints.toString(),
        owner: deployer.address,
      },
    },
  };

  const filename = path.join(deploymentsDir, `exchange-${networkName}.json`);
  fs.writeFileSync(filename, JSON.stringify(deploymentInfo, null, 2));
  console.log("\n💾 Deployment info saved to:", filename);

  console.log("\n" + "=".repeat(50));
  console.log("✅ Deployment completed!");
  console.log("=".repeat(50));
  console.log("\nNext steps:");
  console.log("1. Verify contract on Etherscan:");
  console.log(`   pnpm hardhat verify --network ${networkName} ${exchangeAddress} "${zkkAddress}" "${usdcAddress}" "${deployer.address}"`);
  console.log("\n2. Add to .env:");
  console.log(`   FIXED_EXCHANGE_${networkName.toUpperCase()}=${exchangeAddress}`);
  console.log("\n3. Deposit USDC collateral:");
  console.log("   - Approve USDC: usdc.approve(exchangeAddress, amount)");
  console.log("   - Deposit: exchange.depositCollateral(amount)");
  console.log("\n4. Test redemption:");
  console.log("   - Mint some ZKK tokens");
  console.log("   - Approve ZKK: zkk.approve(exchangeAddress, amount)");
  console.log("   - Redeem: exchange.redeem(amount)");
  console.log("=".repeat(50));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
