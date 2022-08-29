// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './LandingToken.sol';


contract Protocol is Ownable{
    LandingToken private _landingToken;

    struct RentDetail{
        uint256 rentAmount;
        uint8 month;
    }

    struct PropertyDetail{
        bytes imageCID;
        bytes legalDocCID;
        RentDetail[] rentdetails;
    }

    mapping (uint256=>PropertyDetail) private _propertyDetails;

    constructor() {
      _landingToken = new LandingToken();
      _oracle = new 
      _landingToken.transferOwnership(msg.sender);
    }
}