// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './LandingToken.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Protocol is Ownable{
    LandingToken private landingToken;

    constructor() {
      landingToken = new LandingToken();
      landingToken.transferOwnership(msg.sender);
    }
}