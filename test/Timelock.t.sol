// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "../lib/forge-std/src/Test.sol";
import { Counter } from "../src/Counter.sol";
import { TimelockController } from "../src/TimelockController.sol";
import { AccessControl } from "../src/AccessControl.sol";

contract TimelockTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
