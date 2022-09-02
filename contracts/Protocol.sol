// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './LandingToken.sol';
import './interfaces/IOracle.sol';


contract Protocol is Ownable{
    LandingToken private _landingToken;
    IOracle private _oracle;
    address[] buyerAddresses;

    struct Claim {
        uint16 hoursClaimable;
        uint256 amountPerHour;
    }
    
    // address => timestamp => claimable amount
    mapping (address => mapping(uint256 => Claim)) totalLandcAllocated;
    uint256 private _totalClaimable;

    // The timestamp of 12:00 am of the first day of the month 
    uint256 private _lastTimestampRentDistributed;
    
    
    struct PropertyDetail{
        bytes imageCID;
        bytes legalDocCID;
    }

    mapping (uint256=>PropertyDetail) private _properties;

    event PayLANDC(
        string date, // "month-year" 
        uint256 propertyID,
        uint256 amount,
        address rentPayer
    );

    event BuyLANDC(
        address buyer,
        uint256 amount,
        uint256 timestamp,
        uint256 usdPaid
    );

     event SellLANDC(
        address seller,
        uint256 amount,
        uint256 timestamp,
        uint256 usdPaid
    );

    event PayRentLANDC(
        address rentPayer,
        uint256 amount,
        uint256 timestamp
    );

    constructor(address oracleAddress, uint256 intialTimestamp) {
      _landingToken = new LandingToken();
      _oracle = IOracle(oracleAddress);
      _oracle.initialize(address(_landingToken));
      _lastTimestampRentDistributed = intialTimestamp; // !!! IMPORTANT TO SET THIS RIGHT
    }

    function buyLANDC(uint256 usdAmount, uint256 txID) external {
        uint256 priceInWei = _landingToken.getPrice();
        uint256 amount = priceInWei*usdAmount;
        require(_landingToken.balanceOf(address(_landingToken))>= amount, "Not enough balance");
        if(_landingToken.balanceOf(msg.sender) == 0){
            buyerAddresses.push(msg.sender);
        }
        bool usdPaid = _oracle.checkBuyTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        uint256 burnAmount = amount * 4 /100;
        uint256 amountTransferred = amount - burnAmount;
        _landingToken.burn(burnAmount);
        _landingToken.buyToken(amountTransferred, msg.sender);
        emit BuyLANDC(msg.sender, amountTransferred, block.timestamp, usdAmount);
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

    function sellLANDC(uint256 userAddressIndex, uint256 usdAmount, uint256 txID) external {
        uint256 priceInWei = _landingToken.getPrice();
        uint256 amount = priceInWei*usdAmount;
        require(_landingToken.balanceOf(address(msg.sender))>= amount, "Not enough balance");
        if(_landingToken.balanceOf(msg.sender) == amount){
            require(buyerAddresses[userAddressIndex] == msg.sender, "Wrong user index");
            buyerAddresses[userAddressIndex] = buyerAddresses[buyerAddresses.length - 1];
            buyerAddresses.pop();
        }
        bool usdPaid = _oracle.checkSellTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        _landingToken.sellToken(amount, msg.sender);
        emit SellLANDC(msg.sender, amount, block.timestamp, usdAmount);
    }

    function addProperty(uint256 _propertyID, bytes memory imageCID, bytes  memory legalDocCID) external onlyOwner {
        require(_properties[_propertyID].imageCID.length == 0, "Property already exist");
        _properties[_propertyID].imageCID = imageCID;
        _properties[_propertyID].legalDocCID = legalDocCID;
    }

    function getProperty(uint256 propertyID) external view returns(PropertyDetail memory) {
        return _properties[propertyID];
    }

    function payRentLandc(uint256 amount, string memory _date, uint256 _propertyID) external{
        require(_properties[_propertyID].imageCID.length == 0, "Property already exist");
        require(_landingToken.balanceOf(msg.sender) >= amount, "Not enogh balance");
        _landingToken.payToProtocol(amount, msg.sender);
        emit PayLANDC(_date, _propertyID, amount, msg.sender);
        emit PayRentLANDC(msg.sender, amount, block.timestamp);
    }

    function convertUSDRentToLandc(uint256 amount, uint256 usdAmount, uint256 rentTxID) external onlyOwner {
        uint256 mainWaletBalance = _landingToken.balanceOf(address(_landingToken));
        bool usdPaid = _oracle.checkRentTx(rentTxID, usdAmount);
        require(usdPaid, "USD not paid");
        if(mainWaletBalance < amount){
            _landingToken.mint(amount - mainWaletBalance);
        }
        _landingToken.payToProtocol(amount, msg.sender);  
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
    function distributePayment(uint256 rentToDistribute, uint256 timestamp) external onlyOwner {
        require(_landingToken.balanceOf(address(this)) >= _totalClaimable+rentToDistribute, "Not enough balance in protocol contract");       
        uint16 hoursInMonths = getHours(timestamp);
        require(hoursInMonths != 0, "Timestamp given is incorrect");
        uint256 totalAddress = buyerAddresses.length;
        uint256 eachClaimablePerHour = (rentToDistribute/totalAddress)/uint256(hoursInMonths);
        for (uint256 index = 0; index < totalAddress; index++) {
            totalLandcAllocated[buyerAddresses[index]][timestamp].hoursClaimable  = hoursInMonths;
            totalLandcAllocated[buyerAddresses[index]][timestamp].amountPerHour  = eachClaimablePerHour;
        }
        _totalClaimable += rentToDistribute;
        _lastTimestampRentDistributed = timestamp;
    }

    function getClaimable(uint256 timestamp) external view returns(uint256){
        return totalLandcAllocated[msg.sender][timestamp].hoursClaimable * totalLandcAllocated[msg.sender][timestamp].amountPerHour;
    }

    function getTotalSaving() external view onlyOwner returns(uint256) {
        return _landingToken.balanceOf(address(this)) - _totalClaimable;
    }

    function claimLANDC(uint256 timestamp) external{
        uint256 claimablePerHour = totalLandcAllocated[msg.sender][timestamp].amountPerHour;
        require(claimablePerHour != 0, "No claimable landc");
        uint256 hoursClaimable = uint256(totalLandcAllocated[msg.sender][timestamp].hoursClaimable);

        uint256 hoursPassed = (block.timestamp-timestamp)/3600;
        uint256 totalClaimable;
        if(hoursPassed >= hoursClaimable){     
             totalClaimable =  hoursClaimable*claimablePerHour;      
            totalLandcAllocated[msg.sender][timestamp].amountPerHour = 0;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimable = 0;
        }
        else{
            totalClaimable = hoursPassed*claimablePerHour;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimable -= uint16(hoursPassed);
        }
        _totalClaimable -= totalClaimable;
         _landingToken.transfer(msg.sender, totalClaimable);
    }    
    
}