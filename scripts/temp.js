const { ethers } = require("hardhat");
require("dotenv").config();
const csa = require("../artifacts/contracts/Crowdsale.sol/Crowdesale.json");
const tokenAbi = require("../artifacts/contracts/token.sol/FlameToken.json");

const toWei = (num) => ethers.parseEther(num.toString());

const provider = new ethers.JsonRpcProvider(
  "https://data-seed-prebsc-1-s1.binance.org:8545"
);

const wallet = new ethers.Wallet(
  "ecfc25e59cd52529212388d1591131974c2cefbd9e0993e9ccdb5fa2b112da95",
  provider
);

const contract = new ethers.Contract(
  "0xDf46f605502C91c499d073f574DE25a02b16e5A1",
  csa.abi,
  wallet
);

const tokenContract = new ethers.Contract(
  "0xE30cC852B17aAcF418DDf3ed310B509653341A32",
  tokenAbi.abi,
  wallet
);

const transferTokenToIco = async () => {
  const result = await tokenContract.mint(
    "0xAcE7deFd7b310c6a0260dcEAe3539922500A2183",
    toWei(1000000000000)
  );
  console.log(result.hash);
};

const main = async () => {
  // const result = await contract.affiliates(
  //   "0x80A344d8095d099bb72e6298aA8bA2C9E82A4Cbe"
  // );
  // console.log(result);
  await transferTokenToIco();
};

main().catch((err) => {
  console.log(err);
});
