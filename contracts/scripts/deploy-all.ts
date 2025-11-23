import { execSync } from "child_process";
import { ethers } from "hardhat";

/**
 * Deploy all contracts in correct order
 * Usage: pnpm hardhat run scripts/deploy-all.ts --network sepolia
 */

function runScript(scriptPath: string, network: string) {
  console.log(`\n🚀 Running: ${scriptPath}`);
  try {
    execSync(`pnpm hardhat run ${scriptPath} --network ${network}`, {
      stdio: "inherit",
    });
  } catch (error) {
    console.error(`❌ Failed to run ${scriptPath}`);
    throw error;
  }
}

async function main() {
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? process.env.HARDHAT_NETWORK || "hardhat" : network.name;

  console.log("=".repeat(60));
  console.log("🚀 Deploying All Contracts");
  console.log("=".repeat(60));
  console.log("Network:", networkName);
  console.log("=".repeat(60));

  // Step 1: Deploy MockUSDC
  console.log("\n" + "=".repeat(60));
  console.log("Step 1: Deploying MockUSDC");
  console.log("=".repeat(60));
  runScript("scripts/deploy-usdc.ts", networkName);

  // Step 2: Deploy ZKK OFT
  console.log("\n" + "=".repeat(60));
  console.log("Step 2: Deploying ZKK OFT");
  console.log("=".repeat(60));
  runScript("scripts/deploy-zkk.ts", networkName);

  // Step 3: Deploy FixedExchange
  console.log("\n" + "=".repeat(60));
  console.log("Step 3: Deploying FixedExchange");
  console.log("=".repeat(60));
  runScript("scripts/deploy-exchange.ts", networkName);

  console.log("\n" + "=".repeat(60));
  console.log("✅ All Contracts Deployed!");
  console.log("=".repeat(60));
  console.log("\n📋 Summary:");
  console.log("  ✅ MockUSDC deployed");
  console.log("  ✅ ZKK OFT deployed");
  console.log("  ✅ FixedExchange deployed");

  console.log("\n🎯 Next Steps:");
  console.log("1. Verify contracts on Etherscan");
  console.log("2. Run setup script:");
  console.log(`   pnpm hardhat run scripts/setup-demo.ts --network ${networkName}`);
  console.log("\n3. If deploying cross-chain:");
  console.log("   - Deploy on another network (e.g., baseSepolia)");
  console.log("   - Run: pnpm hardhat run scripts/configure-layerzero.ts");
  console.log("=".repeat(60));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
