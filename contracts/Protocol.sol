// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './LandingToken.sol';
import './interfaces/IOracle.sol';


contract Protocol is Ownable{
    LandingToken private _landingToken;
    IOracle private _oracle;

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
        bool usdPaid = _oracle.checkBuyTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        _landingToken.buyToken(amount, msg.sender);
    }
    
}