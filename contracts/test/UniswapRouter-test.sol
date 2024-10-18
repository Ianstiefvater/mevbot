// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MockUniswapRouter {
    // Función que simula swapExactTokensForTokens de Uniswap
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata /* path */,
        address /* to */,
        uint /* deadline */
    ) external pure returns (uint256[2] memory amounts) {
        // Simulas que la cantidad mínima solicitada es la que se devuelve
        amounts = [amountOutMin, amountIn];
        return amounts;
    }

    // Función que simula getAmountsOut de Uniswap
    function getAmountsOut(uint256 amountIn, address[] calldata /* path */) external pure returns (uint256[2] memory amounts) {
        // Devuelve la cantidad de entrada y supongamos no hay pérdida en el intercambio
        amounts = [amountIn, amountIn];
        return amounts;
    }
}




