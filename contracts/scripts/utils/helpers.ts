import fs from "fs";
import path from "path";

/**
 * Load deployment address from deployments directory
 */
export function loadDeployment(contractName: string, network: string) {
  const deploymentsDir = path.join(process.cwd(), "deployments");
  const filename = path.join(deploymentsDir, `${contractName.toLowerCase()}-${network}.json`);

  if (!fs.existsSync(filename)) {
    throw new Error(
      `Deployment file not found: ${filename}\n` +
      `Please deploy ${contractName} on ${network} first.`
    );
  }

  const deployment = JSON.parse(fs.readFileSync(filename, "utf8"));
  return deployment;
}

/**
 * Save deployment info to deployments directory
 */
export function saveDeployment(
  contractName: string,
  network: string,
  chainId: number,
  deployer: string,
  contractData: Record<string, any>
) {
  const deploymentsDir = path.join(process.cwd(), "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  const deploymentInfo = {
    network,
    chainId,
    deployer,
    timestamp: new Date().toISOString(),
    contracts: {
      [contractName]: contractData,
    },
  };

  const filename = path.join(deploymentsDir, `${contractName.toLowerCase()}-${network}.json`);
  fs.writeFileSync(filename, JSON.stringify(deploymentInfo, null, 2));

  return filename;
}

/**
 * Wait for transaction with better logging
 */
export async function waitForTx(tx: any, description?: string) {
  if (description) {
    console.log(`  ${description}`);
  }
  console.log(`  Transaction: ${tx.hash}`);
  const receipt = await tx.wait();
  console.log(`  ✅ Confirmed in block ${receipt.blockNumber}`);
  return receipt;
}

/**
 * Format big numbers for display
 */
export function formatAmount(amount: bigint, decimals: number = 18): string {
  const divisor = 10n ** BigInt(decimals);
  const wholePart = amount / divisor;
  const fractionalPart = amount % divisor;

  if (fractionalPart === 0n) {
    return wholePart.toString();
  }

  const fractionalStr = fractionalPart.toString().padStart(decimals, "0");
  const trimmed = fractionalStr.replace(/0+$/, "");

  return `${wholePart}.${trimmed}`;
}

/**
 * Display a nice separator
 */
export function separator(char: string = "=", length: number = 60) {
  console.log(char.repeat(length));
}

/**
 * Display section header
 */
export function section(title: string) {
  separator();
  console.log(title);
  separator();
}
