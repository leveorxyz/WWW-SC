// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IERC20.sol';

contract Protocol is Ownable{
    IERC20 private _erc20;

    uint256[] private _buyUSDTxIDs;       
    uint256[] private _sellUSDTxIDs;       

    constructor(address _erc20Address) {
        _erc20 = IERC20(_erc20Address);
    }

    modifier onlyERC20() {
        require(msg.sender == address(_erc20));
        _;
    }

    function addBuyTx(uint256 buyUSDTx) external onlyOwner{
        _buyUSDTxIDs.push(buyUSDTx);
    }

    function addSellTx(uint256 sellUSDTx) external onlyOwner{
        _sellUSDTxIDs.push(sellUSDTx);
    }

    function checkBuyTx(uint256 buyUSDTx) external onlyERC20 returns(bool) {
        for (uint256 index = 0; index < _buyUSDTxIDs.length; index++) {
            if (_buyUSDTxIDs[index] == buyUSDTx) {
                delete _buyUSDTxIDs[index];
                return true;
            } 
        }
        return false;
    }

    function checkSellTx(uint256 sellUSDTx) external onlyERC20 returns(bool) {
        for (uint256 index = 0; index < _sellUSDTxIDs.length; index++) {
            if (_sellUSDTxIDs[index] == sellUSDTx) {
                delete _buyUSDTxIDs[index];
                return true;
            } 
        }
        return false;
    }

}