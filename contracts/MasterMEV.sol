// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Arbitrage.sol";
import "./Sandwich.sol";
import "./Liquidation.sol";

contract MasterMEV is ReentrancyGuard {
    address public immutable owner;
    mapping(address => uint256) public moduleFunds; // Fondos asignados a cada módulo

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
            
    // Permite la recepción de fondos y registra el evento
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    event FundsReceived(address sender, uint amount);

    function allocateFunds(address module, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds in MasterMEV");
        moduleFunds[module] += amount;
    }

    function withdrawFunds(address payable recipient, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds");
        recipient.transfer(amount);
    }

    function reportProfit(address module, uint256 profit) external {
        require(msg.sender == module, "Only designated modules can report profits");
        moduleFunds[module] += profit;
    }

    // Asigna fondos y prepara los parámetros para un ataque sandwich
    function prepareSandwichAttack(uint amountIn, uint amountOutMin, address[] calldata path, uint deadline, address sandwichModule) external onlyOwner {
        require(moduleFunds[sandwichModule] >= amountIn, "Insufficient funds allocated");
        Sandwich(sandwichModule).setupSandwichAttack(amountIn, amountOutMin, path, deadline);
    }

    // Asigna fondos y prepara los parámetros para arbitraje (pospuesto las operaciones de arbitraje hasta que el MEV pueda financiar los costes de API de precios, pero la función seguirá aquí aunque no será llamada externamente ya que el .js no será desarrollado por ahora e integrado a index)
    function prepareArbitrage(uint amountIn, uint amountOutMin, address[] calldata path, address dexAddress, uint deadline, address arbitrageModule) external onlyOwner {
        require(moduleFunds[arbitrageModule] >= amountIn, "Insufficient funds allocated");
        Arbitrage(arbitrageModule).setupArbitrage(amountIn, amountOutMin, path, dexAddress, deadline);
    }

    // Asigna fondos y prepara los parámetros para liquidación incluyendo la dirección del token
    function prepareLiquidation(address borrower, address platformAddress, address tokenAddress, address liquidationModule) external onlyOwner {
        require(moduleFunds[liquidationModule] >= 0, "Insufficient funds allocated for liquidation");
        Liquidation(liquidationModule).setupLiquidation(borrower, platformAddress, tokenAddress);
    }
}
