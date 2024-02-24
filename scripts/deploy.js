const hre = require("hardhat");

async function main() {
  tokenContract = await hre.ethers.deployContract("FlameToken");
  await tokenContract.waitForDeployment();

  // const oneYear = 31536000; // 60 * 60 * 24 * 365
  const affiliateContract = await hre.ethers.deployContract(
    "AffiliateProgram",
    [/* Commission rate */ 18, /* token Address */ tokenContract.target]
  );

  await affiliateContract.waitForDeployment();
  console.log(`Affliate contract deployed at: ${affiliateContract.target}`);
  console.log(`Token deployed at: ${tokenContract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
