const { expect } = require("chai");
const { ethers } = require("hardhat");
require("dotenv").config();

const toWei = (amount) => ethers.parseEther(amount.toString());
const parseAndTruncate = (amount) => {
  const a = ethers.formatEther(amount.toString());
  return Math.trunc(a * 100) / 100;
};

describe("Affiliate test", () => {
  let add1, add2, provider, tokenContract, affiliateContract;
  const mintAmount = toWei(10000000);
  beforeEach(async () => {
    [add1] = await ethers.getSigners();
    provider = new ethers.JsonRpcProvider(process.env.test_network);
    add2 = new ethers.Wallet(
      "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
      provider
    );

    tokenContract = await ethers.deployContract("FlameToken");
    await tokenContract.waitForDeployment();

    affiliateContract = await ethers.deployContract("AffiliateProgram", [
      2,
      tokenContract.target,
    ]);
    await affiliateContract.waitForDeployment();

    await tokenContract.mint(affiliateContract.target, mintAmount);
  });

  it("Should check balance of affiliate contract", async () => {
    const balance = await tokenContract.balanceOf(affiliateContract.target);
    expect(balance).to.equal(mintAmount);
  });

  it("should register affiliate", async () => {
    await affiliateContract.approveAffiliates([add1.address]);
    const res = await affiliateContract.affiliates(add1.address);
    expect(res).to.equal(2);
  });

  it("should add commition to affiliate address", async () => {
    await affiliateContract.approveAffiliates([add1.address]);
    await affiliateContract.addCommission(add1.address, 1000, add2.address);
    const res = await affiliateContract.accumulatedCommission(add1.address);
    expect(res).to.equal(20);
  });

  it("should add multiple commition to affiliate address", async () => {
    await affiliateContract.approveAffiliates([add1.address]);
    await affiliateContract.addCommission(
      add1.address,
      toWei(100),
      add2.address
    );
    await affiliateContract.addCommission(
      add1.address,
      toWei(120),
      add2.address
    );
    const res = await affiliateContract.accumulatedCommission(add1.address);
    expect(parseAndTruncate(res)).to.equal(4.4);
  });

  it("should be able to withdraw commission", async () => {
    await affiliateContract.approveAffiliates([add1.address]);
    await affiliateContract.addCommission(
      add1.address,
      toWei(100),
      add2.address
    );
    const res1 = await affiliateContract.accumulatedCommission(add1.address);
    expect(parseAndTruncate(res1)).to.equal(2);
    await affiliateContract.withdrawCommission();
    const res2 = await affiliateContract.accumulatedCommission(add1.address);
    expect(parseAndTruncate(res2)).to.equal(0);
  });

  it("should revert if commission is not present", async () => {
    await affiliateContract.approveAffiliates([add1.address]);
    await affiliateContract.addCommission(
      add1.address,
      toWei(100),
      add2.address
    );
    await affiliateContract.withdrawCommission();
    const res2 = await affiliateContract.accumulatedCommission(add1.address);
    expect(parseAndTruncate(res2)).to.equal(0);
    expect(
      affiliateContract.accumulatedCommission(add1.address)
    ).to.be.revertedWith("No commission to withdraw");
  });
});
