// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

// Use ERC20 prebuild secure contracts  from OpenZeppelin library.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// use Reentrancy Gaurd to secure  against reentrancy attacks.
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// You can also use Ownable thing to set the contract as a ownership.
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, ReentrancyGuard, Ownable(msg.sender) {
    constructor(uint256 initialSupply) ERC20("Token", "TKN") {
        _mint(msg.sender, initialSupply);
    }
}
