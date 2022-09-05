// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandingToken is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Landing Token", "LANDC") {
        _mint(address(this), 1000000000000 * (10 ** decimals()));
        _approve(address(this), msg.sender, 1000000000000 * (10 ** decimals()));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint256 amount) public onlyOwner {
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
        if(from != address(0) && to != address(0)){
             if (from != address(this)) {
            _approve(from, address(this), this.allowance(from, address(this))-amount);
            } 
            if(to != address(this)){   
                _approve(to, address(this), this.allowance(to, address(this))+amount);
            }
        }
       
        super._beforeTokenTransfer(from, to, amount);
    }

    function buyToken(uint amount, address buyer) external onlyOwner {
        require(this.balanceOf(address(this)) >= amount, "Not enough balance");
        transferFrom(address(this), buyer, amount);
    }

    function sellToken(uint amount, address seller) external onlyOwner {
        require(this.balanceOf(seller) >= amount, "Not enough balance");
        transferFrom(seller, address(this), amount);
    }

    function payToProtocol(uint256 amount, address rentPayer) external onlyOwner{
        transferFrom(rentPayer, msg.sender, amount);
    }

    function getPrice() external view returns(uint256) {
        return totalSupply() / 1000000000000;
    }
}