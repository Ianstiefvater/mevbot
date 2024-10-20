require('dotenv').config();

const config = {
    // Direcciones de los Smart Contracts
    contracts: {
        sandwich: process.env.SANDWICH_CONTRACT_ADDRESS,
        liquidation: process.env.LIQUIDATION_CONTRACT_ADDRESS,
        masterMEV: process.env.MASTER_MEV_CONTRACT_ADDRESS
    },

    // Configuración del Proveedor de Blockchain
    provider: {
        url: process.env.BLOCKCHAIN_PROVIDER_URL, // Este depende del entorno, si es prueba en hardhat es localhost:8545, si es en una red real pero con sepolia entonces es otra, y si es en la mainnet es otra url
        network: process.env.ETHEREUM_NETWORK // Sepolia, Mainnet, hardat
    },

    // Claves API
    apiKeys: {
        alchemy: process.env.ALCHEMY_API_KEY
    },

    // Wallet Configuration
    wallet: {
        privateKey: process.env.WALLET_PRIVATE_KEY // Acá también depende, solo se usa en caso de desplieguen en redes reales tanto con hardhat, sepolia o con mainnet, con sepolia se usa un faucet
    },

    uniswap: {
        uniswap_router: process.env.MOCK_UNISWAP_ROUTER_ADDRESS,
    }
    //Las direcciones ficticias que has desplegado en la red local de Hardhat no serán válidas en Sepolia ni en Mainnet. 
    //Para estas redes, necesitarás desplegar nuevamente tus contratos y utilizar las direcciones de contratos reales de ERC20 y Uniswap Router disponibles en esas redes.
    //La elección del token ERC20 depende de en qué tokens desees operar (por ejemplo, si estás trabajando con ETH o algún otro token ERC20).
};

module.exports = config;
