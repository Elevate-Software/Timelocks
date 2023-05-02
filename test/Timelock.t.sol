// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "../lib/forge-std/src/Test.sol";
import { Counter } from "../src/Counter.sol";
import { TimelockController } from "../src/TimelockController.sol";
import { AccessControl } from "../src/AccessControl.sol";

contract TimelockTest is Test {
    Counter public counter;
    AccessControl public accessControl;
    TimelockController public timelockController;

    function setUp() public {
        counter = new Counter();
        accessControl = new accessControl();

        uint256 minDelay = 2 days; // TODO: CONFIG

        address[] memory proposers; // TODO: CONFIG
        proposers.push(address(this));

        address[] memory executors; // TODO: CONFIG
        executors.push(address(this));

        address admin = address(this);  // TODO: CONFIG

        timelockController = new timelockController(
            minDelay,
            proposers,
            executors,
            admin
        );
    }

    function test_timelock_init_state() public {
    }

    function test_timelock() public {
    }
}
