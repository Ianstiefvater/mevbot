require('dotenv').config();
const { Web3 } = require('web3');
const readline = require('readline');
const config = require('./config');
const { spawn } = require('child_process');
const sandwich = require('./sandwich');
const liquidation = require('./liquidation');

// Inicializa el proveedor de Web3 y los contratos
const web3 = new Web3(config.provider.url);
    

const MasterMEVContract = new web3.eth.Contract(
    require('../artifacts/contracts/MasterMEV.sol/MasterMEV.json').abi,
    config.contracts.masterMEV
);

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});
rl.on('line', (input) => {
    if (input === 'stop') {
        manageFunds();
    }
});
console.log("Bot Starting, to stop it just write stop on the CLI")

async function main() {
    const accounts = await web3.eth.getAccounts();
    const deployer = accounts[0];
    console.log(`Bot starting with deployer account: ${deployer}`);

    await configureInitialFunds(deployer);
    monitorAndExecuteStrategies();
}
async function configureInitialFunds(deployer) {
    const balanceWei = await web3.eth.getBalance(config.contracts.masterMEV);
    const balanceEth = web3.utils.fromWei(balanceWei, 'ether');
    const walletBalanceWei = await web3.eth.getBalance(deployer);
    const walletBalanceEth = web3.utils.fromWei(walletBalanceWei, 'ether');
    console.log(`Current MasterMEV balance: ${balanceEth} ETH`);
    console.log(`Your wallet balance: ${walletBalanceEth} ETH`);

    rl.question('Do you want to add funds to MasterMEV? (y/n): ', (answer) => {
        if (answer.toLowerCase() === 'y') {
            rl.question('Enter amount in ETH to add: ', async (amountEth) => {
                const amountWei = web3.utils.toWei(amountEth, 'ether');
                if (parseFloat(amountWei) > parseFloat(walletBalanceWei)) {
                    console.log('Not enough funds in wallet.');
                    rl.close();
                } else {
                    await web3.eth.sendTransaction({ from: deployer, to: config.contracts.masterMEV, value: amountWei });
                    console.log(`Added ${web3.utils.fromWei(amountWei, 'ether')} ETH to MasterMEV.`);
                    rl.close();
                }
            });
        } else {
            if (balanceWei === '0') {
                console.log('No funds available. Please add funds to continue.');
                process.exit(0);
            } else {
                console.log('Proceeding with existing funds.');
                rl.close();
            }
        }
    });
}
let pendingOpportunities = [];

function monitorAndExecuteStrategies() {
    console.log('Start Monitoring and executing strategies...');

    // Ejecutar sandwich.js en una nueva ventana de comando
    const sandwichProcess = spawn('cmd.exe', ['/c', 'start', 'cmd', '/k', 'node sandwich.js'], { detached: true });
    sandwichProcess.unref();

    // Ejecutar liquidation.js en otra nueva ventana de comando
    const liquidationProcess = spawn('cmd.exe', ['/c', 'start', 'cmd', '/k', 'node liquidation.js'], { detached: true });
    liquidationProcess.unref();

    // Agregar una función para procesar oportunidades
    function processOpportunity(opportunity, type) {
        pendingOpportunities.push({ opportunity, type });
        // Solo verifica y ejecuta si hay múltiples oportunidades o una operación está en curso
        if (pendingOpportunities.length > 1 || isOperationInProgress) {
            checkAndExecuteBestOpportunity();
        }
    }
    

    // Monitorizar oportunidades desde sandwich
    sandwich.monitorTransactions((error, opportunity) => {
        if (error) {
            console.error("Error monitoring sandwiches: ", error);
            return;
        }
        if (opportunity) {
            processOpportunity(opportunity, 'sandwich');
        }
    });

    // Monitorizar oportunidades desde liquidation
    liquidation.checkForLiquidatablePositions((error, opportunity) => {
        if (error) {
            console.error("Error monitoring liquidations: ", error);
            return;
        }
        if (opportunity) {
            processOpportunity(opportunity, 'liquidation');
        }
    });
}

// Evaluar y ejecutar la mejor oportunidad basada en el coeficiente de rentabilidad
let isOperationInProgress = false;
async function checkAndExecuteBestOpportunity() {
    if (pendingOpportunities.length === 0) return;

    const gasPrice = await web3.eth.getGasPrice(); // Obtener el precio del gas una sola vez
    const masterMEVBalance = await web3.eth.getBalance(config.contracts.masterMEV); // Obtener el balance una sola vez

    let bestOpportunity = pendingOpportunities.reduce((best, current) => {
        const bestProfitability = (best.opportunity.potentialProfit - best.opportunity.gasRequired * gasPrice) / masterMEVBalance;
        const currentProfitability = (current.opportunity.potentialProfit - current.opportunity.gasRequired * gasPrice) / masterMEVBalance;
        return (currentProfitability > bestProfitability) ? current : best;
    });

    // Limpiar la lista de oportunidades y marcar como en progreso
    pendingOpportunities = [];
    isOperationInProgress = true;

    // Ejecutar la mejor oportunidad
    await evaluateAndExecute(bestOpportunity.opportunity, bestOpportunity.type, (success) => {
        if (success) {
            console.log(`${bestOpportunity.type} executed successfully.`);
        } else {
            console.log(`${bestOpportunity.type} execution failed.`);
        }
        isOperationInProgress = false;
    });
}



// Función para evaluar y ejecutar estrategias
async function evaluateAndExecute(opportunity, type, callback) {
    try {
        if (type === 'sandwich') {
            const buyResult = await executeSandwichStep(opportunity.buy);
            if (!buyResult.success) {
                console.log(`Failed to execute buy step of sandwich attack: ${buyResult.message}`);
                callback(false);  // Indicar al script para continuar monitoreando
                return;
            }

            console.log('Buy step executed successfully, waiting for the target transaction to confirm...');
            const transactionConfirmed = await waitForTransactionToConfirm(opportunity.targetTransactionHash);

            if (!transactionConfirmed) {
                console.log('Target transaction did not confirm in time, aborting sandwich attack.');
                callback(false);
                return;
            }

            const sellResult = await executeSandwichStep(opportunity.sell);
            if (!sellResult.success) {
                console.log(`Failed to execute sell step of sandwich attack: ${sellResult.message}`);
                callback(false);
                return;
            }

            console.log(`Successfully executed sandwich attack with profit: ${sellResult.profit}`);
            callback(true);
        } else if (type === 'liquidation') {
            const executionResult = await executeLiquidationStep(opportunity);
            if (!executionResult.success) {
                console.log(`Failed to execute liquidation: ${executionResult.message}`);
                callback(false);
                return;
            }

            console.log(`Successfully executed liquidation with profit: ${executionResult.profit}`);
            callback(true);
        }
    } catch (error) {
        console.error(`Error executing ${type}: ${error.message}`);
        callback(false);
    }
}

async function executeSandwichStep(stepDetails) {
    const gasPrice = await web3.eth.getGasPrice();
    const txCost = gasPrice * stepDetails.gasRequired;
    const potentialProfit = stepDetails.potentialProfit;

    const profitabilityCoefficient = (potentialProfit - txCost) / stepDetails.investment;

    if (profitabilityCoefficient > 0.005) {
        try {
            const result = await MasterMEVContract.methods.prepareSandwichAttack(
                stepDetails.amountIn, 
                stepDetails.amountOutMin, 
                stepDetails.path, 
                stepDetails.deadline, 
                config.contracts.sandwich
            ).send({ from: config.wallet.address });
            return { success: true, profit: result.events.DebugInfo.returnValues.profit };
        } catch (error) {
            return { success: false, message: error.message };
        }
    } else {
        return { success: false, message: 'Low profitability' };
    }
}

async function executeLiquidationStep(opportunity) {
    const gasPrice = await web3.eth.getGasPrice();
    const txCost = gasPrice * opportunity.gasRequired;
    const potentialProfit = opportunity.potentialProfit;

    const profitabilityCoefficient = (potentialProfit - txCost) / opportunity.investment;

    if (profitabilityCoefficient > 0.005) {
        try {
            const result = await MasterMEVContract.methods.prepareLiquidation(
                opportunity.borrower,
                opportunity.platformAddress,
                opportunity.tokenAddress,
                config.contracts.liquidation
            ).send({ from: config.wallet.address });
            return { success: true, profit: result.events.DebugInfo.returnValues.profit };
        } catch (error) {
            return { success: false, message: error.message };
        }
    } else {
        return { success: false, message: 'Low profitability' };
    }
}

async function waitForTransactionToConfirm(transactionHash) {
    return new Promise((resolve, reject) => {
        web3.eth.getTransactionReceipt(transactionHash, (error, receipt) => {
            if (error) {
                reject(error);
            }
            resolve(receipt && receipt.status);
        });
    });
}

// Función para retirar fondos al final del día, si se desea
async function manageFunds(deployer) {
    const balanceWei = await web3.eth.getBalance(config.contracts.masterMEV);
    const balanceEth = web3.utils.fromWei(balanceWei, 'ether');
    console.log(`MasterMEV contract balance: ${balanceEth} ETH`);

    rl.question('Do you want to withdraw funds? (y/n): ', async (withdraw) => {
        if (withdraw.toLowerCase() === 'y') {
            rl.question('Enter amount in ETH to withdraw: ', async (amountEth) => {
                const amountWei = web3.utils.toWei(amountEth, 'ether');
                if (parseFloat(amountWei) > parseFloat(balanceWei)) {
                    console.log('Not enough funds in the contract.');
                    rl.close();
                } else {
                    await MasterMEVContract.methods.withdrawFunds(deployer, amountWei).send({ from: deployer });
                    console.log(`Withdrawn ${amountEth} ETH back to deployer: ${deployer}`);
                    rl.close();
                }
            });
        } else {
            console.log('No funds withdrawn.');
            rl.close();
        }
    });
}

main().catch(console.error);
