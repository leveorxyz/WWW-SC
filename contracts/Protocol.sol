// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import './LandingToken.sol';
import './interfaces/IOracle.sol';


contract Protocol is Ownable{
    LandingToken private _landingToken;
    IOracle private _oracle;
    address[] buyerAddresses;

    // address => year => month => claimable amount
    mapping (address => mapping(uint16 => mapping(uint8 => uint256))) totalLandcAllocated;
    uint256 private _totalClaimable;
    
    
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

    constructor(address oracleAddress) {
      _landingToken = new LandingToken();
      _oracle = IOracle(oracleAddress);
      _oracle.initialize(address(_landingToken));
    }

    modifier checkMonth(uint8 month) {
        require(month > 0 && month < 13, "Not a month");
        _;
    }

    modifier checkYear(uint16 year) {
        require(year > 2021, "Not a valid year");
        _;
    }

    function buyLANDC(uint256 amount, uint256 usdAmount, uint256 txID) external {
        require(_landingToken.balanceOf(address(_landingToken))>= amount, "Not enough balance");
        if(_landingToken.balanceOf(msg.sender) == 0){
            buyerAddresses.push(msg.sender);
        }
        bool usdPaid = _oracle.checkBuyTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        _landingToken.buyToken(amount, msg.sender);
        emit BuyLANDC(msg.sender, amount, block.timestamp, usdAmount);
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

    function distributePayment(uint256 rentToDistribute, uint8 month, uint16 year) external onlyOwner checkMonth(month) checkYear(year) {
        require(_landingToken.balanceOf(address(this)) >= _totalClaimable+rentToDistribute, "Not enough balance in protocol contract");       
        uint256 totalAddress = buyerAddresses.length;
        uint256 eachClaimable = rentToDistribute/totalAddress;
        for (uint256 index = 0; index < totalAddress; index++) {
            totalLandcAllocated[buyerAddresses[index]][year][month] += eachClaimable;
        }
        _totalClaimable += rentToDistribute;
    }

    function getClaimable(uint8 month, uint16 year) external view checkMonth(month) checkYear(year) returns(uint256){
        return totalLandcAllocated[msg.sender][year][month];
    }

    function getTotalSaving() external view onlyOwner returns(uint256) {
        return _landingToken.balanceOf(address(this)) - _totalClaimable;
    }

    
    
}