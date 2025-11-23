import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

/**
 * Deploy MockUSDC token for testing
 * Usage: pnpm hardhat run scripts/deploy-usdc.ts --network sepolia
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();

  console.log("=".repeat(50));
  console.log("Deploying MockUSDC");
  console.log("=".repeat(50));
  console.log("Network:", network.name);
  console.log("Chain ID:", network.chainId);
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");
  console.log("=".repeat(50));

  // Deploy MockUSDC
  console.log("\n📝 Deploying MockUSDC...");
  const MockUSDC = await ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();

  const usdcAddress = await usdc.getAddress();
  console.log("✅ MockUSDC deployed to:", usdcAddress);

  // Verify deployment
  const decimals = await usdc.decimals();
  const symbol = await usdc.symbol();
  const balance = await usdc.balanceOf(deployer.address);

  console.log("\n📊 Token Details:");
  console.log("  Symbol:", symbol);
  console.log("  Decimals:", decimals);
  console.log("  Deployer balance:", ethers.formatUnits(balance, decimals), symbol);

  // Save deployment info
  const deploymentInfo = {
    network: network.name,
    chainId: Number(network.chainId),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      MockUSDC: {
        address: usdcAddress,
        symbol: symbol,
        decimals: Number(decimals),
      },
    },
  };

  const deploymentsDir = path.join(process.cwd(), "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  const filename = path.join(deploymentsDir, `usdc-${network.name}.json`);
  fs.writeFileSync(filename, JSON.stringify(deploymentInfo, null, 2));
  console.log("\n💾 Deployment info saved to:", filename);

  console.log("\n" + "=".repeat(50));
  console.log("✅ Deployment completed!");
  console.log("=".repeat(50));
  console.log("\nNext steps:");
  console.log("1. Verify contract on Etherscan:");
  console.log(`   pnpm hardhat verify --network ${network.name} ${usdcAddress}`);
  console.log("\n2. Add to .env:");
  console.log(`   MOCK_USDC_${network.name.toUpperCase()}=${usdcAddress}`);
  console.log("=".repeat(50));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
