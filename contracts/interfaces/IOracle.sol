// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IOracle {
    function initialize(address _erc20Address) external;
    function checkBuyTx(string memory buyUSDTx, uint256 amount) external returns(bool);
    function checkSellTx(string memory sellUSDTx, uint256 amount) external returns(bool); 
    function checkRentTx(string memory rentUSDTx, uint256 amount) external returns(bool);
}