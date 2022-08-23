// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IERC20.sol';

contract Protocol is Ownable{
    IERC20 private _erc20;

    uint256[] private _buyUSDTxIDs;       
    uint256[] private _sellUSDTxIDs;       
    uint256[] private _rentUSDTxIDs;       

    constructor(address _erc20Address) {
        _erc20 = IERC20(_erc20Address);
    }

    modifier onlyERC20() {
        require(msg.sender == address(_erc20));
        _;
    }

    function addBuyTx() external onlyOwner{
        
    }

    function addSellTx() external onlyOwner{
        
    }

    function addRentTx() external onlyOwner{
        
    }
}