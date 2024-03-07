const hre = require("hardhat");
require("dotenv").config();

async function main() {
  const tokenContract = await hre.ethers.deployContract("FlameToken");
  await tokenContract.waitForDeployment();
  const twoYear = 31536000 * 2; // 60 * 60 * 24 * 365

  const affiliateContract = await hre.ethers.deployContract("Crowdesale", [
    process.env.admin_address,
    tokenContract.target,
    process.env.usdt_address,
    hre.ethers.parseEther("1000000000"),
    process.env.AggregatorV3Interface,
    5,
    5,
  ]);
  await affiliateContract.waitForDeployment();

  const stakingAndDivident = await hre.ethers.deployContract(
    "StakingAndDivident",
    [process.env.usdt_address, tokenContract.target, 5, twoYear]
  );
  await stakingAndDivident.waitForDeployment();
  console.log(`Token deployed at: ${tokenContract.target}`);
  console.log(`Affliate contract deployed at: ${affiliateContract.target}`);
  console.log(`Staking deployed at: ${stakingAndDivident.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
