// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './LandingToken.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Protocol is Ownable{
    LandingToken private landingToken;

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
      landingToken = new LandingToken();
      landingToken.transferOwnership(msg.sender);
    }
}