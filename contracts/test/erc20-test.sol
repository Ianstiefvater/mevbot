// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimpleERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 totalSupply_;

    constructor(string memory _name, string memory _symbol, uint256 total) {
        name = _name;
        symbol = _symbol;
        totalSupply_ = total;
        balances[msg.sender] = total;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view override returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender], "Insufficient balance.");
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view override returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner], "Insufficient balance.");
        require(numTokens <= allowed[owner][msg.sender], "Insufficient allowance.");

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}
