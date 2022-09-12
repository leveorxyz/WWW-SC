// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './LandingToken.sol';

contract Protocol is Ownable{
    LandingToken private _landingToken;
  
    address private _masterAccount;

    struct Claim {
        uint16 hoursClaimable;
        bool claimSet;
        uint256 amountPerHour;
        uint256 hoursClaimed;
    }

    struct TotalClaim{
        uint256 eachClaimablePerHour;
        uint256 hoursInMonth;
        uint256 totalClaimedSet;
    }
    
    // address => timestamp => claimable amount
    mapping (address => mapping(uint256 => Claim)) totalLandcAllocated;
    uint256 private _totalClaimable;
    mapping(uint256 => TotalClaim) private totalClaimDetails;

    uint256 private _maintenanceVaultAmount;

    // The timestamp of 12:00 am of the first day of the month 
    uint256 private _lastTimestampRentDistributed;
    

    constructor(address _oracleAddress, uint256 _intialTimestamp, address __masterAccount) {
      _landingToken = new LandingToken(_oracleAddress, address(this));
      _masterAccount = __masterAccount;
      _lastTimestampRentDistributed = _intialTimestamp; // !!! IMPORTANT TO SET THIS RIGHT
    }

    function getLandingTokenAddress() public view returns(address) {
        return address(_landingToken);
    }


    function getHours(uint256 timestamp) internal view returns(uint16) {
        uint256 timeDif = timestamp - _lastTimestampRentDistributed;
        // seconds in a day: 86400 => 86400*31 = 2678400 
        if(timeDif == 2592000){
            return 720; // 30*24 
        }
        else if(timeDif == 2678400){
            return 744; // 31*24 
        }
        else if(timeDif == 2419200){
            return 672; // 28*24 
        }
        else if(timeDif == 2505600){
            return 696; // 29*24 
        }
        return 0;
    }

    // !!! Timestamp should be 12 am first day of the Month
    function distributePayment(uint256 rentToDistribute, uint256 maintainiaceAmount, uint256 timestamp) external onlyOwner {
        require(_landingToken.balanceOf(address(this)) >= _totalClaimable+rentToDistribute+maintainiaceAmount, "Not enough balance in protocol contract");       
        require(block.timestamp>timestamp, "Month have not past");
        uint16 hoursInMonths = getHours(timestamp);
        require(hoursInMonths != 0, "Timestamp given is incorrect");
        uint256 totalAddress = _landingToken.getTotalBuyers();
        uint256 eachClaimablePerHour = (rentToDistribute/totalAddress)/uint256(hoursInMonths);

        totalClaimDetails[timestamp].eachClaimablePerHour = eachClaimablePerHour;
        totalClaimDetails[timestamp].hoursInMonth = hoursInMonths;
        totalClaimDetails[timestamp].totalClaimedSet = block.timestamp;
        
        _totalClaimable += rentToDistribute;
        _maintenanceVaultAmount += maintainiaceAmount;
        _lastTimestampRentDistributed = timestamp;
    }

    function claimMaintenanceFee(uint256 amount) external {
        require(msg.sender == _masterAccount, "Not the master account");
        require(amount <= _maintenanceVaultAmount, "Not enough maintenance fee to collect");
        require(_landingToken.balanceOf(address(this)) >= _totalClaimable+_maintenanceVaultAmount, "Not enough balance in protocol contract");       
        _maintenanceVaultAmount -= amount;
        _landingToken.transfer(msg.sender, amount);
    }

    function getMaintenanceFee() external view returns(uint256) {
        require(msg.sender == _masterAccount, "Not the master account");
        return _maintenanceVaultAmount;
    }

    function getTotalClaimableInMonth(uint256 timestamp) external view returns(uint256){
        if(totalLandcAllocated[msg.sender][timestamp].claimSet){
            return totalLandcAllocated[msg.sender][timestamp].hoursClaimable * totalLandcAllocated[msg.sender][timestamp].amountPerHour;
        }
        return totalClaimDetails[timestamp].eachClaimablePerHour*totalClaimDetails[timestamp].hoursInMonth;
    }


    function getClaimable(uint256 timestamp) public view returns(uint256) {
        require(totalLandcAllocated[msg.sender][timestamp].claimSet, "Call getTotalClaimableInMonth instead");
        uint256 claimablePerHour = totalLandcAllocated[msg.sender][timestamp].amountPerHour;
        uint256 hoursClaimable = uint256(totalLandcAllocated[msg.sender][timestamp].hoursClaimable);
        uint256 claimedSeconds = totalLandcAllocated[msg.sender][timestamp].hoursClaimed*3600;
        if(claimablePerHour == 0 || hoursClaimable == 0 || block.timestamp<timestamp+claimedSeconds){
            return 0;
        }
       
        uint256 hoursPassed = (block.timestamp-timestamp-claimedSeconds)/3600;
        uint256 totalClaimable = 0;
        if(hoursPassed >= hoursClaimable){     
             totalClaimable =  hoursClaimable*claimablePerHour;      
        }
        else{
            totalClaimable = hoursPassed*claimablePerHour;
        }
        return totalClaimable;
    }

    function getTotalSaving() external view onlyOwner returns(uint256) {
        return _landingToken.balanceOf(address(this)) - _totalClaimable;
    }

    function claimLANDC(uint256 timestamp) external{
        uint256 claimablePerHour = totalLandcAllocated[msg.sender][timestamp].amountPerHour;
        require(claimablePerHour != 0, "No claimable landc");
        uint256 claimedSeconds = totalLandcAllocated[msg.sender][timestamp].hoursClaimed*3600;
        uint256 hoursClaimable = uint256(totalLandcAllocated[msg.sender][timestamp].hoursClaimable);
        require(hoursClaimable != 0, "No claimable currently");
        require(block.timestamp>timestamp+claimedSeconds, "Month have not past");
        uint256 hoursPassed = (block.timestamp-timestamp-claimedSeconds)/3600;
        uint256 totalClaimable;
        if(hoursPassed >= hoursClaimable){     
             totalClaimable =  hoursClaimable*claimablePerHour;      
            totalLandcAllocated[msg.sender][timestamp].amountPerHour = 0;
             totalLandcAllocated[msg.sender][timestamp].hoursClaimed += hoursClaimable;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimable = 0;
        }
        else{
            totalClaimable = hoursPassed*claimablePerHour;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimed += hoursPassed;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimable -= uint16(hoursPassed);
        }
        _totalClaimable -= totalClaimable;
         _landingToken.transfer(msg.sender, totalClaimable);
    }    
    
}