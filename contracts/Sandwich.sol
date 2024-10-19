// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC20.sol";

interface IUniswapV2Router {  
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}



contract Sandwich is ReentrancyGuard {
    IUniswapV2Router public immutable uniswapRouter;
    address public immutable owner;

    constructor(address _router) {
        uniswapRouter = IUniswapV2Router(_router);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    event DebugInfo(uint256 indexed value, address indexed fromAddress);

    // Configura y ejecuta un ataque Sandwich
    function setupSandwichAttack(uint amountIn, uint amountOutMin, address[] calldata path, uint deadline) external onlyOwner nonReentrant {
        require(IERC20(path[0]).approve(address(uniswapRouter), amountIn), "Approval failed");
        
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        require(amounts.length > 0 && amounts[0] >= amountOutMin, "Swap failed");

        // Enviar los fondos resultantes y reportar ganancias
        uint256 totalFunds = IERC20(path[path.length - 1]).balanceOf(address(this));
        IERC20(path[path.length - 1]).transfer(msg.sender, totalFunds);  // enviar de vuelta a MasterMEV o a quien llame

        uint profit = amounts[amounts.length - 1] - amountIn;
        emit DebugInfo(profit, msg.sender); // Reportar ganancia

        emit DebugInfo(amountIn, msg.sender);
        emit DebugInfo(amounts[0], address(this));
    }
}
