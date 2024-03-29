// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Oracle is Ownable{

    bool called;

    // txID -> usd amount
    mapping(string => uint256) private _buyUSDTxIDs;       
    mapping (string => uint256) private _sellUSDTxIDs;       
    mapping (string => uint256) private _rentUSDTxIDs;     

    event AddBuyTx(
        string txID,
        uint256 amount,
        uint256 timestamp
    );

    event AddSellTx(
        string txID,
        uint256 amount,
        uint256 timestamp
    );

    event AddRentTx(
        string txID,
        uint256 amount,
        uint256 timestamp
    );

    address private _erc20Address; 

    constructor() {
    }

    modifier onlyERC20() {
        require(msg.sender != address(0), "Can not be empty address");
        require(msg.sender == _erc20Address);
        _;
    }

    function initialize(address __erc20Address) external {
        require(!called, "Can initialize only once");
        _erc20Address= __erc20Address;
        called = false;
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
        emit AddBuyTx(buyUSDTx, amount, block.timestamp);
    }

    function addSellTx(string memory sellUSDTx, uint256 amount) external onlyOwner sellUsdTxIDDontExixt(sellUSDTx) amountNotZero(amount){ 
        _sellUSDTxIDs[sellUSDTx] = amount;
        emit AddSellTx(sellUSDTx, amount, block.timestamp);

    }

    function addRentTx(string memory rentUSDTx, uint256 amount) external onlyOwner rentUsdTxIDDontExixt(rentUSDTx) amountNotZero(amount){ 
        _rentUSDTxIDs[rentUSDTx] = amount;
        emit AddRentTx(rentUSDTx, amount, block.timestamp);

    }

    function checkBuyTx(string memory buyUSDTx, uint256 amount) external onlyERC20 amountNotZero(amount) returns(bool) {
        bool exist =  _buyUSDTxIDs[buyUSDTx] == amount;
        if(exist){
            delete _buyUSDTxIDs[buyUSDTx];
        }
        return exist;
    }

    function checkSellTx(string memory sellUSDTx, uint256 amount) external onlyERC20 amountNotZero(amount) returns(bool) {
        bool exist = _sellUSDTxIDs[sellUSDTx] == amount;
        if(exist){
            delete _sellUSDTxIDs[sellUSDTx];
        }
        return exist;
    }

    function checkRentTx(string memory rentUSDTx, uint256 amount) external onlyERC20 amountNotZero(amount) returns(bool) {
        bool exist = _rentUSDTxIDs[rentUSDTx] == amount;
        if(exist){
            delete _rentUSDTxIDs[rentUSDTx];
        }
        return exist;
    }

}