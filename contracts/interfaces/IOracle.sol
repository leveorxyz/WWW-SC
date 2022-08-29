// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IOracle {
    function initialize(address _erc20Address) external;
    function checkBuyTx(uint256 buyUSDTx, uint256 amount) external returns(bool);
    function checkSellTx(uint256 sellUSDTx, uint256 amount) external returns(bool); 
}