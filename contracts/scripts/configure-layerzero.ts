import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

/**
 * Configure LayerZero peers for cross-chain communication
 * This script sets up trusted peers between ZKK deployments on different chains
 *
 * Usage: pnpm hardhat run scripts/configure-layerzero.ts
 */

// LayerZero Endpoint IDs (EIDs) for testnets
const CHAIN_IDS: Record<string, number> = {
  sepolia: 40161,
  baseSepolia: 40245,
};

// RPC URLs - fallback if not in env
const RPC_URLS: Record<string, string> = {
  sepolia: process.env.SEPOLIA_RPC_URL || "",
  baseSepolia: process.env.BASE_SEPOLIA_RPC_URL || "",
};

async function main() {
  console.log("=".repeat(60));
  console.log("LayerZero Cross-Chain Configuration");
  console.log("=".repeat(60));

  const deploymentsDir = path.join(process.cwd(), "deployments");

  // Load deployments
  const sepoliaFile = path.join(deploymentsDir, "zkk-sepolia.json");
  const baseSepoliaFile = path.join(deploymentsDir, "zkk-baseSepolia.json");

  if (!fs.existsSync(sepoliaFile)) {
    throw new Error("Sepolia deployment not found. Deploy on Sepolia first.");
  }
  if (!fs.existsSync(baseSepoliaFile)) {
    throw new Error("Base Sepolia deployment not found. Deploy on Base Sepolia first.");
  }

  const sepoliaDeployment = JSON.parse(fs.readFileSync(sepoliaFile, "utf8"));
  const baseSepoliaDeployment = JSON.parse(fs.readFileSync(baseSepoliaFile, "utf8"));

  const sepoliaZKK = sepoliaDeployment.contracts.ZKK.address;
  const baseSepoliaZKK = baseSepoliaDeployment.contracts.ZKK.address;

  console.log("\n📋 Deployments Found:");
  console.log("  Sepolia ZKK:", sepoliaZKK);
  console.log("  Base Sepolia ZKK:", baseSepoliaZKK);
  console.log("\n🔗 LayerZero Endpoint IDs:");
  console.log("  Sepolia EID:", CHAIN_IDS.sepolia);
  console.log("  Base Sepolia EID:", CHAIN_IDS.baseSepolia);

  // Connect to both networks
  console.log("\n" + "=".repeat(60));
  console.log("Configuring Sepolia → Base Sepolia");
  console.log("=".repeat(60));

  if (!RPC_URLS.sepolia) {
    throw new Error("SEPOLIA_RPC_URL not set in environment");
  }

  const sepoliaProvider = new ethers.JsonRpcProvider(RPC_URLS.sepolia);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, sepoliaProvider);

  console.log("\n📝 Setting peer on Sepolia...");
  console.log("  Signer:", wallet.address);
  console.log("  Balance:", ethers.formatEther(await sepoliaProvider.getBalance(wallet.address)), "ETH");

  const sepoliaContract = await ethers.getContractAt("ZKK", sepoliaZKK, wallet);

  // Encode the peer address (remove 0x and pad to 32 bytes)
  const peerAddress = ethers.zeroPadValue(baseSepoliaZKK, 32);

  console.log("\n  Setting peer:");
  console.log("    Remote Chain EID:", CHAIN_IDS.baseSepolia);
  console.log("    Remote ZKK Address:", baseSepoliaZKK);
  console.log("    Encoded Peer:", peerAddress);

  const tx1 = await sepoliaContract.setPeer(CHAIN_IDS.baseSepolia, peerAddress);
  console.log("  Transaction sent:", tx1.hash);
  await tx1.wait();
  console.log("  ✅ Peer set on Sepolia");

  // Configure Base Sepolia → Sepolia
  console.log("\n" + "=".repeat(60));
  console.log("Configuring Base Sepolia → Sepolia");
  console.log("=".repeat(60));

  if (!RPC_URLS.baseSepolia) {
    throw new Error("BASE_SEPOLIA_RPC_URL not set in environment");
  }

  const baseSepoliaProvider = new ethers.JsonRpcProvider(RPC_URLS.baseSepolia);
  const baseSepoliaWallet = new ethers.Wallet(process.env.PRIVATE_KEY!, baseSepoliaProvider);

  console.log("\n📝 Setting peer on Base Sepolia...");
  console.log("  Signer:", baseSepoliaWallet.address);
  console.log("  Balance:", ethers.formatEther(await baseSepoliaProvider.getBalance(baseSepoliaWallet.address)), "ETH");

  const baseSepoliaContract = await ethers.getContractAt("ZKK", baseSepoliaZKK, baseSepoliaWallet);

  const sepoliaPeerAddress = ethers.zeroPadValue(sepoliaZKK, 32);

  console.log("\n  Setting peer:");
  console.log("    Remote Chain EID:", CHAIN_IDS.sepolia);
  console.log("    Remote ZKK Address:", sepoliaZKK);
  console.log("    Encoded Peer:", sepoliaPeerAddress);

  const tx2 = await baseSepoliaContract.setPeer(CHAIN_IDS.sepolia, sepoliaPeerAddress);
  console.log("  Transaction sent:", tx2.hash);
  await tx2.wait();
  console.log("  ✅ Peer set on Base Sepolia");

  // Verify configuration
  console.log("\n" + "=".repeat(60));
  console.log("Verifying Configuration");
  console.log("=".repeat(60));

  const sepoliaPeer = await sepoliaContract.peers(CHAIN_IDS.baseSepolia);
  const baseSepoliaPeer = await baseSepoliaContract.peers(CHAIN_IDS.sepolia);

  console.log("\n✅ Verification:");
  console.log("  Sepolia peer for Base Sepolia:", sepoliaPeer);
  console.log("  Expected:", peerAddress);
  console.log("  Match:", sepoliaPeer === peerAddress ? "✓" : "✗");

  console.log("\n  Base Sepolia peer for Sepolia:", baseSepoliaPeer);
  console.log("  Expected:", sepoliaPeerAddress);
  console.log("  Match:", baseSepoliaPeer === sepoliaPeerAddress ? "✓" : "✗");

  console.log("\n" + "=".repeat(60));
  console.log("✅ LayerZero Configuration Complete!");
  console.log("=".repeat(60));
  console.log("\nYou can now send cross-chain transactions:");
  console.log("1. From Sepolia to Base Sepolia");
  console.log("2. From Base Sepolia to Sepolia");
  console.log("\nTest cross-chain transfer:");
  console.log("  - Use LayerZero's send() function");
  console.log("  - Monitor on LayerZero Scan: https://testnet.layerzeroscan.com");
  console.log("=".repeat(60));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
