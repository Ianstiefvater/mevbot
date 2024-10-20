// Importa las funcionalidades de Hardhat
require('dotenv').config();
const { ethers } = require("hardhat");


async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // estos en el.env serán los deployeados de prueba para hardhat, luego serán los reales
    const routerAddress = process.env.MOCK_UNISWAP_ROUTER_ADDRESS;  

    // Despliegue de Sandwich
    const Sandwich = await ethers.getContractFactory("Sandwich");
    const sandwich = await Sandwich.deploy(routerAddress);
    await sandwich.deployed();
    console.log("Sandwich contract deployed to:", sandwich.address);

    // Despliegue de Liquidation
    const Liquidation = await ethers.getContractFactory("Liquidation");
    const liquidation = await Liquidation.deploy();
    await liquidation.deployed();
    console.log("Liquidation contract deployed to:", liquidation.address);

    // Despliegue de MasterMEV
    const MasterMEV = await ethers.getContractFactory("MasterMEV");
    const masterMEV = await MasterMEV.deploy();
    await masterMEV.deployed();
    console.log("MasterMEV contract deployed to:", masterMEV.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});

