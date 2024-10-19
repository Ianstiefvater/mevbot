// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC20.sol";

interface IDEXRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


contract Arbitrage is ReentrancyGuard {
    address public immutable owner;
    mapping(address => IDEXRouter) public routers;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setRouter(address dexAddress, address router) public onlyOwner {
        routers[dexAddress] = IDEXRouter(router);
    }

    // Esta función permite configurar y ejecutar arbitraje directamente desde MasterMEV
    function setupArbitrage(uint amountIn, uint amountOutMin, address[] calldata path, address dexAddress, uint deadline) external onlyOwner nonReentrant {
        IDEXRouter router = routers[dexAddress];
        require(address(router) != address(0), "Router not set");

        require(IERC20(path[0]).approve(address(router), amountIn), "Approval failed");

        uint[] memory amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        require(amounts[amounts.length - 1] >= amountOutMin, "Arbitrage failed to meet profit threshold");

        // Enviar los fondos resultantes y reportar ganancias
        uint256 totalFunds = IERC20(path[path.length - 1]).balanceOf(address(this));
        IERC20(path[path.length - 1]).transfer(msg.sender, totalFunds);  // enviar de vuelta a MasterMEV o a quien llame
    }
}
