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

    receive() external payable {}

    event DebugInfo(uint256 indexed value, address indexed fromAddress);

    // Aseguramos la ejecución correcta utilizando el patrón Checks-Effects-Interactions
    function executeSandwichAttack(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external onlyOwner {
        // Check
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        require(IERC20(path[0]).approve(address(uniswapRouter), amountIn), "Approve failed");
        
        // Interaction
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        require(amounts.length > 0 && amounts[0] >= amountOutMin, "Swap failed");

        // Emitimos eventos después de efectuar las interacciones
        emit DebugInfo(amountIn, msg.sender);
        emit DebugInfo(amounts[0], address(this));
    }

    function withdrawToken(address token, uint amount) public onlyOwner {
        require(IERC20(token).transfer(owner, amount), "Transfer failed");
    }

    function withdrawETH(uint amount) public onlyOwner {
        payable(owner).transfer(amount);
    }
}
