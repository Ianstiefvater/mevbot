// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract Sandwich {
    IUniswapV2Router public uniswapRouter;
    address public owner;

    constructor(address _router) {
        uniswapRouter = IUniswapV2Router(_router);
        owner = msg.sender;
    }
    // Modifier se usa para cambiar el comportamiento de las funciones de una manera declarativa
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Function to allow contract to receive ETH
    receive() external payable {}

    // Main function to execute a sandwich attack
    function executeSandwichAttack(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external onlyOwner {
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");

        require(IERC20(path[0]).approve(address(uniswapRouter), amountIn), "Approve failed");

        // Execute the swap from the token to another token
        uniswapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    // Function to withdraw tokens from the contract
    function withdrawToken(address token, uint amount) public onlyOwner {
        require(IERC20(token).transfer(owner, amount), "Transfer failed");
    }


    // Function to withdraw ETH from the contract
    function withdrawETH(uint amount) public onlyOwner {
        payable(owner).transfer(amount);
    }
}