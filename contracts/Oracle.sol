// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Oracle is Ownable{

    address private _protocolAddress;
    bool called;

    // txID -> usd amount
    mapping(string => uint256) private _buyUSDTxIDs;       
    mapping (string => uint256) private _sellUSDTxIDs;       
    mapping (string => uint256) private _rentUSDTxIDs;       

    constructor() {
    }

    function initialize() external {
        require(!called, "Can initialize only once");
        _protocolAddress = msg.sender;
        called = false;
    }

    modifier onlyProtocolAddress() {
        require(msg.sender != address(0), "Can not be empty address");
        require(msg.sender == _protocolAddress, "Only called by protocol address");
        _;
    }

    modifier buyUsdTxIDDontExixt(string memory buyUSDTx) {
        require(_buyUSDTxIDs[buyUSDTx] == 0, "Buy tx already added");
        _;
    }

    modifier sellUsdTxIDDontExixt(string memory sellUSDTx) {
        require(_sellUSDTxIDs[sellUSDTx] == 0, "Sell tx already added");
        _;
    }

    modifier rentUsdTxIDDontExixt(string memory rentUSDTx) {
        require(_rentUSDTxIDs[rentUSDTx] == 0, "Rent tx already added");
        _;
    }

    modifier amountNotZero(uint256 amount) {
        require(amount != 0, "USD amount cant be 0");
        _;
    }

    function addBuyTx(string memory buyUSDTx, uint256 amount) external onlyOwner buyUsdTxIDDontExixt(buyUSDTx) amountNotZero(amount){
        _buyUSDTxIDs[buyUSDTx] = amount;
    }

    function addSellTx(string memory sellUSDTx, uint256 amount) external onlyOwner sellUsdTxIDDontExixt(sellUSDTx) amountNotZero(amount){ 
        _sellUSDTxIDs[sellUSDTx] = amount;
    }

    function addRentTx(string memory rentUSDTx, uint256 amount) external onlyOwner rentUsdTxIDDontExixt(rentUSDTx) amountNotZero(amount){ 
        _rentUSDTxIDs[rentUSDTx] = amount;
    }

    function checkBuyTx(string memory buyUSDTx, uint256 amount) external onlyProtocolAddress amountNotZero(amount) returns(bool) {
        bool exist =  _buyUSDTxIDs[buyUSDTx] == amount;
        if(exist){
            delete _buyUSDTxIDs[buyUSDTx];
        }
        return exist;
    }

    function checkSellTx(string memory sellUSDTx, uint256 amount) external onlyProtocolAddress amountNotZero(amount) returns(bool) {
        bool exist = _sellUSDTxIDs[sellUSDTx] == amount;
        if(exist){
            delete _sellUSDTxIDs[sellUSDTx];
        }
        return exist;
    }

    function checkRentTx(string memory rentUSDTx, uint256 amount) external onlyProtocolAddress amountNotZero(amount) returns(bool) {
        bool exist = _rentUSDTxIDs[rentUSDTx] == amount;
        if(exist){
            delete _rentUSDTxIDs[rentUSDTx];
        }
        return exist;
    }

}