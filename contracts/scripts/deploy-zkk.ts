import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

/**
 * Deploy ZKK OFT token on a network
 * Usage: pnpm hardhat run scripts/deploy-zkk.ts --network sepolia
 */

// LayerZero V2 Testnet Endpoints
const LZ_ENDPOINTS: Record<string, string> = {
  sepolia: "0x6EDCE65403992e310A62460808c4b910D972f10f",
  baseSepolia: "0x6EDCE65403992e310A62460808c4b910D972f10f",
};

// Default project ID for demo
const DEFAULT_PROJECT_ID = ethers.id("ZakoKen-Demo-Project");

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? process.env.HARDHAT_NETWORK || "hardhat" : network.name;

  console.log("=".repeat(50));
  console.log("Deploying ZKK OFT Token");
  console.log("=".repeat(50));
  console.log("Network:", networkName);
  console.log("Chain ID:", network.chainId);
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");
  console.log("=".repeat(50));

  // Get LayerZero endpoint for this network
  const lzEndpoint = LZ_ENDPOINTS[networkName];
  if (!lzEndpoint) {
    throw new Error(`LayerZero endpoint not configured for network: ${networkName}`);
  }
  console.log("\n🔗 LayerZero Endpoint:", lzEndpoint);

  // Deploy ZKK
  console.log("\n📝 Deploying ZKK OFT...");
  const ZKK = await ethers.getContractFactory("ZKK");
  const zkk = await ZKK.deploy(
    "ZakoKen",        // name
    "ZKK",            // symbol
    lzEndpoint,       // LayerZero endpoint
    deployer.address, // owner
    DEFAULT_PROJECT_ID // projectId
  );
  await zkk.waitForDeployment();

  const zkkAddress = await zkk.getAddress();
  console.log("✅ ZKK OFT deployed to:", zkkAddress);

  // Verify deployment
  const name = await zkk.name();
  const symbol = await zkk.symbol();
  const decimals = await zkk.decimals();
  const projectId = await zkk.projectId();

  console.log("\n📊 Token Details:");
  console.log("  Name:", name);
  console.log("  Symbol:", symbol);
  console.log("  Decimals:", decimals);
  console.log("  Project ID:", projectId);
  console.log("  LayerZero Endpoint:", lzEndpoint);
  console.log("  Owner:", deployer.address);

  // Save deployment info
  const deploymentInfo = {
    network: networkName,
    chainId: Number(network.chainId),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      ZKK: {
        address: zkkAddress,
        name: name,
        symbol: symbol,
        decimals: Number(decimals),
        projectId: projectId,
        lzEndpoint: lzEndpoint,
        owner: deployer.address,
      },
    },
  };

  const deploymentsDir = path.join(process.cwd(), "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  const filename = path.join(deploymentsDir, `zkk-${networkName}.json`);
  fs.writeFileSync(filename, JSON.stringify(deploymentInfo, null, 2));
  console.log("\n💾 Deployment info saved to:", filename);

  console.log("\n" + "=".repeat(50));
  console.log("✅ Deployment completed!");
  console.log("=".repeat(50));
  console.log("\nNext steps:");
  console.log("1. Verify contract on Etherscan:");
  console.log(`   pnpm hardhat verify --network ${networkName} ${zkkAddress} "ZakoKen" "ZKK" "${lzEndpoint}" "${deployer.address}" "${DEFAULT_PROJECT_ID}"`);
  console.log("\n2. Add to .env:");
  console.log(`   ZKK_OFT_${networkName.toUpperCase()}=${zkkAddress}`);
  console.log("\n3. If deploying cross-chain:");
  console.log("   - Deploy on other chain (e.g., Base Sepolia)");
  console.log("   - Run: pnpm hardhat run scripts/configure-layerzero.ts");
  console.log("=".repeat(50));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
