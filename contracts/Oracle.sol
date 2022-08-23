// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Protocol is Ownable{

    uint256[] private _buyUSDTxIDs;       
    uint256[] private _sellUSDTxIDs;       
    uint256[] private _rentUSDTxIDs;       

    constructor() {
    }

    
}