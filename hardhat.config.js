require("@nomiclabs/hardhat-waffle");
require('dotenv').config();


module.exports = {
  solidity: "0.8.26",
  networks: {
    hardhat: {
      chainId: 1337
    },
    // Sepolia: Se comenta mientras se testee localmente con la red de hardhat
    // sepolia: {
    //   url: "https://eth-sepolia.g.alchemy.com/v2/nCRMSdfRHHl4iorJMej4TrLGyS5QLwbM",
    //   accounts: [`0x${process.env.WALLET_PRIVATE_KEY}`]
    // }
  }
};

