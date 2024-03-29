// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IOracle.sol';

contract LandingToken is ERC20, ERC20Burnable, Pausable, Ownable {

    uint256 intialMint = 1000000000000;

    mapping (address=>uint256) private _buyers;
    uint256 numberOfBuyers;
    address [] allBuyers;
  
    IOracle private _oracle;

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

    struct PropertyDetail{
        bytes imageCID;
        bytes legalDocCID;
    }

    mapping (string=>PropertyDetail) private _properties;

    event PayRentLANDC(
        address rentPayer,
        string propertyID,
        uint256 amount,
        uint256 date,
        uint256 timestamp
    );

    address private _protocolAddress;

    constructor(address _oracleAddress, address __protocolAddress, address ownerAddress) ERC20("Landing Token", "LANDC") {
        intialMint = 1000000000000;
        _oracle = IOracle(_oracleAddress);
        _protocolAddress= __protocolAddress;
        _oracle.initialize(address(this));
        _mint(address(this), intialMint * (10 ** decimals()));
        transferOwnership(ownerAddress);
        // _approve(address(this), msg.sender, intialMint * (10 ** decimals()));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint256 amount) internal {
        intialMint += amount;
        // _approve(address(this), msg.sender, intialMint * (10 ** decimals()));
        _mint(address(this), amount);
    }

    //  function burn(uint256 amount) public virtual onlyOwner override {
    //     _burn(address(this), amount);
    // }

    function approve(address spender, uint256 amount)
        public 
        virtual
        whenNotPaused
        override
        returns (bool)
       {
         require(spender != address(this), "Can not change allowance for landing token");
         return super.approve(spender, amount);
       } 

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if(from != address(0) && to != address(0) && to != address(this) && to != _protocolAddress){
            if (this.balanceOf(to) == 0) {
                _buyers[to] = block.timestamp;
                numberOfBuyers++;
                allBuyers.push(to);
            }
        }
        
        // if(from != address(0) && to != address(0)){
        //      if (from != address(this)) {
        //     _approve(from, address(this), this.allowance(from, address(this))-amount);
        //     } 
        //     if(to != address(this)){   
        //         _approve(to, address(this), this.allowance(to, address(this))+amount);
        //     }
        // }
       
        super._beforeTokenTransfer(from, to, amount);
    }

    function getBuyer(address addressToCheck) public view returns(uint256) {
        return _buyers[addressToCheck];
    }

    function getAllBuyersAddress() public view  returns(address [] memory){
        return allBuyers;
    }

    function getTotalBuyers() public view returns(uint256) {
        return numberOfBuyers;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if(from != address(0) && to != address(0)){
             if (from == address(this)) {
              _approve(to, address(this), this.balanceOf(to));
            } 
            else if(to == address(this)){   
                _approve(from, address(this), this.balanceOf(from));
            }
            else{
              if(from != _protocolAddress && this.balanceOf(from) == 0){
                numberOfBuyers--;
                _buyers[from] = 0;
              }
              _approve(to, address(this), this.balanceOf(to));
              _approve(from, address(this), this.balanceOf(from));
            }
        }
       
        super._afterTokenTransfer(from, to, amount);
    }

    function buyLANDC(uint256 usdAmount, string memory txID) external {
        uint256 amount = ((usdAmount*10**36)/(this.getPrice()));
        require(this.balanceOf(address(this)) >= amount, "Not enough balance");

        bool usdPaid = _oracle.checkBuyTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        uint256 burnAmount = ((amount * 4)/100);
        uint256 amountTransferred = amount-burnAmount;
        _burn(address(this), burnAmount);
       
        emit BuyLANDC(msg.sender, amountTransferred, block.timestamp, usdAmount);
        // _approve(msg.sender, this(address), this.allowance(buyer, msg.sender)+amount);
        this.transfer(msg.sender, amountTransferred);
    }

    function sellLANDC(uint256 usdAmount, string memory txID) external {
        uint256 amount = ((usdAmount*10**36)/(this.getPrice()));
        require(this.balanceOf(msg.sender) >= amount, "Not enough balance");
 
        bool usdPaid = _oracle.checkSellTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
       
        this.transferFrom(msg.sender, address(this), amount);
        emit SellLANDC(msg.sender, amount, block.timestamp, usdAmount);

    }

    function addProperty(string memory _propertyID, bytes memory imageCID, bytes  memory legalDocCID) external onlyOwner {
        require(_properties[_propertyID].imageCID.length == 0, "Property already exist");
        _properties[_propertyID].imageCID = imageCID;
        _properties[_propertyID].legalDocCID = legalDocCID;
    }

    function getProperty(string memory propertyID) external view returns(PropertyDetail memory) {
        return _properties[propertyID];
    }

    // _date => first timestamp of start of the month
    function payRentLandc(uint256 amount, uint256 _date, string memory _propertyID) external{
        require(_properties[_propertyID].imageCID.length != 0, "Property do not exist");
        require(this.balanceOf(msg.sender) >= amount, "Not enogh balance");
        this.transferFrom(msg.sender, _protocolAddress, amount);
        
        emit PayRentLANDC(msg.sender, _propertyID, amount, _date, block.timestamp);
    }

    function convertUSDRentToLandc(uint256 usdAmount, string memory rentTxID) external onlyOwner {
        uint256 mainWaletBalance = this.balanceOf(address(this));
        
        bool usdPaid = _oracle.checkRentTx(rentTxID, usdAmount);
        require(usdPaid, "USD not paid");
        uint256 amount = ((usdAmount*10**36)/(this.getPrice()));
        if(mainWaletBalance < amount){
            mint(amount - mainWaletBalance);
        }
        this.transfer(_protocolAddress, amount);
    }

    function getPrice() external view returns(uint256) {
        return (intialMint * 10 ** decimals())/(totalSupply()/ 10 ** decimals());
    }
}