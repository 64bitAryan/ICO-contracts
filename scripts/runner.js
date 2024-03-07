const { ethers } = require("hardhat");
require("dotenv").config();
const affiliateAbi = require("../artifacts/contracts/Affiliate.sol/AffiliateProgram.json");
const tokenAbi = require("../artifacts/contracts/token.sol/FlameToken.json");

const toWei = (amount) => ethers.parseEther(amount.toString());
const parseAndTruncate = (amount) => {
  const a = ethers.formatEther(amount.toString());
  return Math.trunc(a * 100) / 100;
};

const contractAddress = {
  FlameToken: "0xD3d4769c4d98454A7c7e51ceF7F5A815748e009A",
  AffiliateProgram: "0x6E3c5405Af51e17C9379E71fd5e0698Aa3236aa2",
};

const addAffiliateAddress = async () => {
  const provider = new ethers.JsonRpcProvider(process.env.sepolia_network);
  const Wallet = new ethers.Wallet(process.env.admin_private_key, provider);
  const affiliateContract = new ethers.Contract(
    contractAddress.AffiliateProgram,
    affiliateAbi.abi,
    Wallet
  );
  const addresses = [
    "0xDA7c841EE34AF6Aa9d50457E7b5477BD9192dBAa",
    "0x72FcefCe2BA336cA627fB23802d25320e9005bB6",
    "0xD14791fdDa7f3Ba198B6B5895597ec83117363C1",
    "0x80A344d8095d099bb72e6298aA8bA2C9E82A4Cbe",
    "0x56050f19bcbd8ac5e7462ca198e57d0a8867352b",
    "0xAcEE58007ff44A4A7BeC752E0a4b97AF56D1B9e7",
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
    "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
    "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
    "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
    "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
    "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720",
    "0xbcd4042de499d14e55001ccbb24a551f3b954096",
    "0x71bE63f3384f5fb98995898A86B02Fb2426c5788",
    "0xFABB0ac9d68B0B445fB7357272Ff202C5651694a",
    "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",
    "0xdD2FD4581271e230360230F9337D5c0430Bf44C0",
    "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E",
    "0x2546BcD3c84621e976D8185a91A922aE77ECEc30",
    "0xcd3B766CCDd6AE721141F452C550Ca635964ce71",
    "0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097",
  ];

  const res = await affiliateContract.approveAffiliates(addresses);
  console.log(res.hash);
  return res.hash;
};

const getGasUsed = async (trxHash) => {
  const provider = new ethers.JsonRpcProvider(process.env.sepolia_network);
  try {
    const receipt = await provider.getTransactionReceipt(trxHash);
    if (receipt) {
      console.log(receipt);
      console.log(__________________________________________);
      console.log("Gas used by the transaction:", receipt.gasUsed.toString());
    } else {
      console.log("Transaction receipt not found.");
    }
  } catch (error) {
    console.error("Error:", error);
  }
};

const mintTokenToContract = async () => {
  const provider = new ethers.JsonRpcProvider(process.env.sepolia_network);
  const Wallet = new ethers.Wallet(process.env.admin_private_key, provider);
  const tokenContract = new ethers.Contract(
    "0x45abF920E3360bE42b48e83ec275f845Df93F329",
    tokenAbi.abi,
    Wallet
  );
  const res = await tokenContract.mint(
    "0xfad6966936179Ea1E90d33DBd27B53b779c81BD2",
    toWei("1000000000000")
  );
  console.log(res.hash);
};

const main = async () => {
  await mintTokenToContract();
};

main().catch((err) => {
  console.log(err);
  process.exitCode(1);
});
