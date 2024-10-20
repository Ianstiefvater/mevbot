// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IERC20.sol";

interface IDeFiPlatform {
    function getCollateralThreshold() external view returns (uint256);
    function getDebt(address borrower) external view returns (uint256);
    function getCollateralValue(address borrower) external view returns (uint256);
    function liquidateBorrower(address borrower) external;
}



contract Liquidation is ReentrancyGuard {
    address public immutable owner;
    mapping(address => IDeFiPlatform) public platforms;  // Mapping of platform addresses to their interfaces

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function setPlatform(address platformAddress, IDeFiPlatform interfaceAddress) public onlyOwner {
        platforms[platformAddress] = interfaceAddress;
    }

    // Setup and execute a liquidation
    function setupLiquidation(address borrower, address platformAddress, address tokenAddress) external onlyOwner nonReentrant {
        IDeFiPlatform platform = platforms[platformAddress];
        require(address(platform) != address(0), "Platform not set");

        uint256 debt = platform.getDebt(borrower);
        uint256 collateral = platform.getCollateralValue(borrower);
        uint256 threshold = platform.getCollateralThreshold();

        require(debt > 0, "No debt to liquidate");
        require(collateral * 100 < debt * threshold, "Collateralization is sufficient");

        platform.liquidateBorrower(borrower);

        uint256 finalBalance = IERC20(tokenAddress).balanceOf(address(this));


        // Transfer the funds back to the caller or MasterMEV
        IERC20(tokenAddress).transfer(owner, finalBalance);  // send all to owner or MasterMEV as assumed

    }
}
