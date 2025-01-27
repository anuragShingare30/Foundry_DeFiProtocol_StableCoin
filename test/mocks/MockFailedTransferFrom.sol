// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


/**
 * @title MockFailedTransferFrom contract
 * @author anurag shingare
 * @notice This is the mock smart contract for transferFrom() which will fail.
 * @dev In tests, we are expecting revert if our transferFrom() fails.
 * @dev So, we will fail the transferFrom() method in this contract.

 * @dev THIS CONTRACT CAN BEHAVE AS MOCK DSC CONTRACT JUST LIKE OUR MAIN DecentralizeStableCoin.sol contract
 */



contract MockFailedTransferFrom is ERC20, ERC20Burnable, Ownable {
    // errors
    error DecentralizeStableCoin_ZeroAmountNotAllowed();
    error DecentralizeStableCoin_TokenBalanceIsLessThanAmount();
    error DecentralizeStableCoin_ZeroAddressNotAllowed();

    // type declaration

    // state variables

    // events

    // functions
    constructor()
        ERC20("DecentralizeStableCoin", "DSC")
        Ownable(msg.sender)
    {}

    function burn(uint256 _burnAmount) public override onlyOwner{
        uint256 balance = balanceOf(msg.sender);
        if(_burnAmount <= 0){
            revert DecentralizeStableCoin_ZeroAmountNotAllowed();
        }
        if(balance < _burnAmount){
            revert DecentralizeStableCoin_TokenBalanceIsLessThanAmount();
        }
        super.burn(_burnAmount);
    }

    function mint(address to, uint256 amount) public onlyOwner returns(bool) {
        if(amount <= 0){
            revert DecentralizeStableCoin_ZeroAmountNotAllowed();
        }
        if(to == address(0)){
            revert DecentralizeStableCoin_ZeroAddressNotAllowed();
        }
        _mint(to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public pure override returns(bool){
        return false;
    }
}
