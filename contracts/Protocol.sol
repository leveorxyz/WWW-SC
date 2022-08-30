// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './LandingToken.sol';
import './interfaces/IOracle.sol';


contract Protocol is Ownable{
    LandingToken private _landingToken;
    IOracle private _oracle;
    address[] buyerAddresses;

    struct RentDetail{
        uint256 rentAmount;
        uint8 month;
        uint8 year;
    }

    struct PropertyDetail{
        bytes imageCID;
        bytes legalDocCID;
        RentDetail[] rentdetails;
    }

    mapping (uint256=>PropertyDetail) private _propertyDetails;

    constructor(address oracleAddress) {
      _landingToken = new LandingToken();
      _oracle = IOracle(oracleAddress);
      _oracle.initialize(address(_landingToken));
    }

    function buyLANDC(uint256 amount, uint256 usdAmount, uint256 txID) external {
        require(_landingToken.balanceOf(address(_landingToken))>= amount, "Not enough balance");
        if(_landingToken.balanceOf(msg.sender) == 0){
            buyerAddresses.push(msg.sender);
        }
        bool usdPaid = _oracle.checkBuyTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        _landingToken.buyToken(amount, msg.sender);
    }

    // view function to get buyer address
    function getBuyerIndex() external view returns(bool, uint256) {
        for (uint256 index = 0; index < buyerAddresses.length; index++) {
            if (buyerAddresses[index] == msg.sender) {
                return (true, index);
            } 
        }
        return(false, 0);        
    }

    function sellLANDC(uint256 amount, uint256 userAddressIndex, uint256 usdAmount, uint256 txID) external {
        require(_landingToken.balanceOf(address(msg.sender))>= amount, "Not enough balance");
        if(_landingToken.balanceOf(msg.sender) == amount){
            require(buyerAddresses[userAddressIndex] == msg.sender, "Wrong user index");
            buyerAddresses[userAddressIndex] = buyerAddresses[buyerAddresses.length - 1];
            buyerAddresses.pop();
        }
        bool usdPaid = _oracle.checkSellTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        _landingToken.sellToken(amount, msg.sender);
    }
    
}