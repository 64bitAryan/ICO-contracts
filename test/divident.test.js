const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
require("dotenv").config();

const toWei = (amount) => ethers.parseEther(amount.toString());

const setBlockTimeWithIncrement = async (additionalTime) => {
  const currentTimeInSeconds = await getCurrentBlockTime();
  await time.increaseTo(currentTimeInSeconds + additionalTime);
};

const getCurrentBlockTime = async () => {
  return await time.latest();
};

const parseAndTruncate = (amount) => {
  const a = ethers.formatEther(amount.toString());
  return Math.trunc(a * 100) / 100;
};

describe("Divident test contract", () => {
  let add1, add2, tokenContract, provider, dividentContract, usdtTokenContract;
  const oneYear = 60 * 60 * 24 * 365 + 5;
  const stakeAmount = toWei(1000);
  const mintAmount = toWei(100000000);
  const sendAmount = toWei("0.001");

  beforeEach(async () => {
    [add1] = await ethers.getSigners();
    provider = new ethers.JsonRpcProvider(process.env.test_network);
    add2 = new ethers.Wallet(
      "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
      provider
    );

    tokenContract = await ethers.deployContract("FlameToken");
    await tokenContract.waitForDeployment();

    usdtTokenContract = await ethers.deployContract("USDTtoken");
    await tokenContract.waitForDeployment();

    dividentContract = await ethers.deployContract("DividentProgram", [
      tokenContract.target,
      usdtTokenContract.target,
      oneYear,
    ]);

    const tx = await add1.sendTransaction({
      to: dividentContract.target,
      value: sendAmount,
    });

    await usdtTokenContract.mint(dividentContract.target, mintAmount);
    await tokenContract.mint(add1.address, mintAmount);
  });

  it("Should check the lockin time", async () => {
    const loginTime = await dividentContract.LOCKIN_TIME();
    expect(loginTime).to.equal(oneYear);
  });

  it("should stake the token", async () => {
    await tokenContract.approve(dividentContract.target, stakeAmount);
    await dividentContract.stake(stakeAmount);
    const res = await dividentContract.stakedAmounts(add1.address, 0);
    expect(res.amount).to.equal(stakeAmount);
  });

  it("Should unstake token and if the claim is pending do that", async () => {
    await tokenContract.approve(dividentContract.target, stakeAmount);
    await dividentContract.stake(stakeAmount);
    await setBlockTimeWithIncrement(oneYear);
    const ethBalance = await provider.getBalance(dividentContract.target);
    const usdtBalance = await usdtTokenContract.balanceOf(
      dividentContract.target
    );
    const tokenTotalSuppy = await tokenContract.totalSupply();
    const dividentReq = (ethBalance + usdtBalance) / tokenTotalSuppy;
    const res = await dividentContract.unstake(0);
    const receipt = await res.wait(1);
    const claimEvent = receipt.logs[1];
    const unstakeEvent = receipt.logs[3];
    expect(claimEvent.args[0]).to.equal(add1.address);
    expect(unstakeEvent.args[0]).to.equal(add1.address);
    expect(claimEvent.fragment["name"]).to.eqls("ClaimDivident");
    expect(unstakeEvent.fragment["name"]).to.eqls("Unstaked");
    const uStake = await dividentContract.stakedAmounts(add1.address, 0);
    expect(uStake.amount).to.equal(0);
  });

  it("should send dividents", async () => {
    await tokenContract.approve(dividentContract.target, stakeAmount);
    await dividentContract.stake(stakeAmount);
    await setBlockTimeWithIncrement(oneYear);
    const ethBalance = await provider.getBalance(dividentContract.target);
    const usdtBalance = await usdtTokenContract.balanceOf(
      dividentContract.target
    );
    const tokenTotalSuppy = await tokenContract.totalSupply();
    const dividentReq = (ethBalance + usdtBalance) / tokenTotalSuppy;
    const res = await dividentContract.claimDivident(0);
    const receipt = await res.wait(1);
    const event = receipt.logs[1];
    const eventName = event.fragment["name"];
    expect(eventName).to.equal("ClaimDivident");
    expect(event.args[2]).to.equal(dividentReq);
  });

  it("Should withdraw eth from the contract", async () => {
    await dividentContract.withdrawEther(add1.address);
    const ethBalance = await provider.getBalance(dividentContract.target);
    expect(ethBalance).to.equal(0);
  });

  it("Should withdraw usdt from the contract", async () => {
    await dividentContract.withdrawUsdt(add1.address);
    const usdtBalance = await usdtTokenContract.balanceOf(
      dividentContract.target
    );
    expect(usdtBalance).to.equal(0);
  });

  it("Should revert if the whtdrawer is not owner", async () => {
    await expect(dividentContract.connect(add2).withdrawEther(add2.address)).to
      .be.reverted;
  });
});
