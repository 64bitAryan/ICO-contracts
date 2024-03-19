require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  defaultNetwork: process.env.working_environment,
  networks: {
    chain_test: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts: [process.env.admin_private_key],
    },
    local_test: {
      url: process.env.test_network,
      accounts: [process.env.test_private_key],
    },
  },
};
