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

    address private _protocolAddress;

    constructor(address _oracleAddress, address __protocolAddress) ERC20("Landing Token", "LANDC") {
        intialMint = 1000000000000;
        _oracle = IOracle(_oracleAddress);
        _protocolAddress= __protocolAddress;
        _mint(address(this), intialMint * (10 ** decimals()));
        _approve(address(this), msg.sender, intialMint * (10 ** decimals()));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint256 amount) public onlyOwner {
        intialMint += amount;
        _approve(address(this), msg.sender, intialMint * (10 ** decimals()));
        _mint(address(this), amount);
    }

     function burn(uint256 amount) public virtual onlyOwner override {
        _burn(address(this), amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if(to != address(0) && to != address(this) && to != _protocolAddress){
            if (this.balanceOf(to) == 0) {
                _buyers[to] = block.timestamp;
                numberOfBuyers++;
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

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if(from != address(0) && to != address(0)){
             if (from == address(this)) {
              _approve(to, address(this), this.balanceOf(from));
            } 
            else if(to == address(this)){   
                _approve(from, address(this), this.balanceOf(to));
            }
            else{
              if(from != _protocolAddress && this.balanceOf(from) == 0){
                numberOfBuyers--;
                _buyers[from] = 0;
              }
              _approve(to, address(this), this.balanceOf(from));
              _approve(from, address(this), this.balanceOf(to));
            }
        }
       
        super._afterTokenTransfer(from, to, amount);
    }

    function buyToken(uint256 usdAmount, string memory txID) external onlyOwner {
        uint256 amount = ((usdAmount*10**36)/(this.getPrice()));
        require(this.balanceOf(address(this)) >= amount, "Not enough balance");

        if(this.balanceOf(msg.sender) == 0){
            _buyers[msg.sender] = block.timestamp;
            numberOfBuyers+=1;
        }
        bool usdPaid = _oracle.checkBuyTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        uint256 burnAmount = ((amount * 4)/100);
        uint256 amountTransferred = amount-burnAmount;
        this.burn(burnAmount);
       
        emit BuyLANDC(msg.sender, amountTransferred, block.timestamp, usdAmount);
        // _approve(buyer, msg.sender, this.allowance(buyer, msg.sender)+amount);
        transferFrom(address(this), msg.sender, amount);
    }

    function sellToken(uint256 usdAmount, string memory txID) external onlyOwner {
        uint256 amount = ((usdAmount*10**36)/(this.getPrice()));
        require(this.balanceOf(msg.sender) >= amount, "Not enough balance");
 
        bool usdPaid = _oracle.checkSellTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
       
        transferFrom(msg.sender, address(this), amount);
        emit SellLANDC(msg.sender, amount, block.timestamp, usdAmount);

    }

    function payToProtocol(uint256 amount, address rentPayer) external onlyOwner{
        transferFrom(rentPayer, msg.sender, amount);
        _approve(rentPayer, msg.sender, this.balanceOf(rentPayer));

    }

    function getPrice() external view returns(uint256) {
        return (intialMint * 10 ** decimals())/(totalSupply()/ 10 ** decimals());
    }
}