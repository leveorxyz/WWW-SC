// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IERC20.sol';

contract Oracle is Ownable{
    IERC20 private _erc20;
    address private _protocolAddress;

    // txID -> usd amount
    mapping(uint256 => uint256) private _buyUSDTxIDs;       
    mapping (uint256 => uint256) private _sellUSDTxIDs;       
    mapping (uint256 => uint256) private _rentUSDTxIDs;       

    constructor() {
    }

    function initialize(address _erc20Address) external {
        _erc20 = IERC20(_erc20Address);
        transferOwnership(msg.sender);      
    }

    modifier onlyERC20() {
        require(msg.sender == address(_erc20));
        _;
    }

    modifier buyUsdTxIDDontExixt(uint256 buyUSDTx) {
        require(_buyUSDTxIDs[buyUSDTx] != 0, "Buy tx already added");
        _;
    }

    modifier sellUsdTxIDDontExixt(uint256 sellUSDTx) {
        require(_sellUSDTxIDs[sellUSDTx] != 0, "Sell tx already added");
        _;
    }

    modifier rentUsdTxIDDontExixt(uint256 sellUSDTx) {
        require(_sellUSDTxIDs[sellUSDTx] != 0, "Rent tx already added");
        _;
    }

    modifier amountNotZero(uint256 amount) {
        require(amount != 0, "USD amount cant be 0");
        _;
    }

    function addBuyTx(uint256 buyUSDTx, uint256 amount) external onlyOwner buyUsdTxIDDontExixt(buyUSDTx) amountNotZero(amount){
        _buyUSDTxIDs[buyUSDTx] = amount;
    }

    function addSellTx(uint256 sellUSDTx, uint256 amount) external onlyOwner sellUsdTxIDDontExixt(sellUSDTx) amountNotZero(amount){ 
        _sellUSDTxIDs[sellUSDTx] = amount;
    }

    function addRentTx(uint256 rentUSDTx, uint256 amount) external onlyOwner rentUsdTxIDDontExixt(rentUSDTx) amountNotZero(amount){ 
        _rentUSDTxIDs[rentUSDTx] = amount;
    }

    function checkBuyTx(uint256 buyUSDTx, uint256 amount) external onlyERC20 buyUsdTxIDDontExixt(buyUSDTx) amountNotZero(amount) returns(bool) {
        bool exist =  _buyUSDTxIDs[buyUSDTx] == amount;
        if(exist){
            delete _buyUSDTxIDs[buyUSDTx];
        }
        return exist;
    }

    function checkSellTx(uint256 sellUSDTx, uint256 amount) external onlyERC20 sellUsdTxIDDontExixt(sellUSDTx) amountNotZero(amount) returns(bool) {
        bool exist = _rentUSDTxIDs[sellUSDTx] == amount;
        if(exist){
            delete _rentUSDTxIDs[sellUSDTx];
        }
        return exist;
    }

    function checkRentTx(uint256 rentUSDTx, uint256 amount) external onlyERC20 rentUsdTxIDDontExixt(rentUSDTx) amountNotZero(amount) returns(bool) {
        bool exist = _rentUSDTxIDs[rentUSDTx] == amount;
        if(exist){
            delete _rentUSDTxIDs[rentUSDTx];
        }
        return exist;
    }

}