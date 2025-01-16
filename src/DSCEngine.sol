// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


/**
 * @title Contract for Decentralize stablecoin engine
 * @author anurag shingare
 * This Contract tries to maintain our token equal to dollar (1 token == 1 dollar).
 * The stablecoin is categorized as:
    a. Exogenous
    b. Algorithmic
    c. Pegged stablecoin
 * @notice This contract is the core if DSC system. It handles all the logic for minting, redeeming DSC, as well as depositing and withdrawing collateral.
 * @dev The contract looselyresemble to MakerDAO/DAI system.
 */

contract DSCEngine{
    
}