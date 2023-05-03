// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Counter is Ownable {

    uint256 public number;

    function setNumber(uint256 newNumber) external onlyOwner {
        require(number != newNumber);
        
        number = newNumber;
    }

    function addNumber(uint256 addNumber) external onlyOwner {
        require(number != 0);
        
        number += addNumber;
    }
}
