// deploy-test.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Despliegue del contrato ERC20 mock
    const SimpleERC20 = await ethers.getContractFactory("SimpleERC20");
    const simpleERC20 = await SimpleERC20.deploy("TestToken", "TT", ethers.utils.parseEther("1000000"));
    await simpleERC20.deployed();
    console.log("SimpleERC20 deployed to:", simpleERC20.address);

    // Despliegue del contrato Uniswap Router mock
    const MockUniswapRouter = await ethers.getContractFactory("MockUniswapRouter");
    const mockUniswapRouter = await MockUniswapRouter.deploy();
    await mockUniswapRouter.deployed();
    console.log("MockUniswapRouter deployed to:", mockUniswapRouter.address);

    // Guarda las direcciones en un archivo o configura variables de entorno
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
