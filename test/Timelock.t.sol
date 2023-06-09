// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "../lib/forge-std/src/Test.sol";
import { Counter } from "../src/Counter.sol";
import { TimelockController } from "../src/TimelockController.sol";
import { AccessControl } from "../src/AccessControl.sol";

contract TimelockTest is Test {
    Counter public counter;
    TimelockController public timelockController;

    function setUp() public {
        counter = new Counter();

        uint256 minDelay = 2 days;

        address[] memory proposers = new address[](1);
        proposers[0] = address(222);

        address[] memory executors = new address[](1);
        executors[0] = address(222);

        address admin = address(222); 

        // initialize timelockController with proper params
        // NOTE: address(222) is playing all roles: admin, executor, proposer
        timelockController = new TimelockController(
            minDelay,
            proposers,
            executors,
            admin
        );

        // give ownership of counter to timelockController
        counter.transferOwnership(address(timelockController));
    }

    // TODO:
    // schedule()       DONE
    // scheduleBatch()  DONE
    // execute()        DONE
    // executeBatch()
    // cancel()
    // updateDelay()

    // NOTE: Proposal: PROPOSER & CANCELLER is a dev wallet & MultiSig, ADMIN and EXECUTOR is the MultiSig
    // TODO: Give this some though

    function test_timelock_init_state() public {
        bytes32 TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
        bytes32 PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
        bytes32 EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
        bytes32 CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
        emit log_bytes32(TIMELOCK_ADMIN_ROLE);
        emit log_bytes32(PROPOSER_ROLE);
        emit log_bytes32(EXECUTOR_ROLE);
        emit log_bytes32(CANCELLER_ROLE);

        assertEq(timelockController.TIMELOCK_ADMIN_ROLE(), TIMELOCK_ADMIN_ROLE);
        assertEq(timelockController.PROPOSER_ROLE(), PROPOSER_ROLE);
        assertEq(timelockController.EXECUTOR_ROLE(), EXECUTOR_ROLE);
        assertEq(timelockController.CANCELLER_ROLE(), CANCELLER_ROLE);
    }

    function test_timelock_schedule() public {

        /// @notice address of smart contract that the timelock should operate on.
        address target = address(counter);

        /// @notice in wei, that should be sent with the transaction. Most of the time this will be 0.
        uint256 value = 0;

        /// @notice containing the encoded function selector and parameters of the call.
        /// @dev This can be produced using a number of tools.
        bytes4 selector = bytes4(keccak256("setNumber(uint256)"));
        bytes memory data = abi.encodeWithSelector(selector, 5);

        /// @notice that specifies a dependency between operations. This dependency is optional.
        /// @dev Use bytes32(0) if the operation does not have any dependency.
        bytes32 predecessor = 0;

        /// @notice used to disambiguate two otherwise identical operations.
        /// @dev This can be any random value.
        bytes32 salt = bytes32(0);

        /// @notice amount of time between scheduling the call and executing the call.
        /// @dev Must be >= minDelay
        uint256 delay = 2 days;

        // Get hash
        bytes32 id = timelockController.hashOperation(target, value, data, predecessor, salt);

        // Call Schedule
        vm.prank(address(222));
        timelockController.schedule(target, value, data, predecessor, salt, delay);

        // Post-State check.
        assertEq(timelockController.getTimestamp(id), block.timestamp + delay);
    }

    function test_timelock_scheduleBatch() public {

        /// @notice address of smart contract that the timelock should operate on.
        address[] memory targets = new address[](2);
        targets[0] = address(counter);
        targets[1] = address(counter);

        /// @notice in wei, that should be sent with the transaction. Most of the time this will be 0.
        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        /// @notice containing the encoded function selector and parameters of the call.
        /// @dev This can be produced using a number of tools.
        bytes[] memory payloads = new bytes[](2);

        bytes4 selector = bytes4(keccak256("setNumber(uint256)"));
        bytes memory data = abi.encodeWithSelector(selector, 5);

        payloads[0] = data;

        selector = bytes4(keccak256("addNumber(uint256)"));
        data = abi.encodeWithSelector(selector, 6);

        payloads[1] = data;

        /// @notice that specifies a dependency between operations. This dependency is optional.
        /// @dev Use bytes32(0) if the operation does not have any dependency.
        bytes32 predecessor = 0;

        /// @notice used to disambiguate two otherwise identical operations.
        /// @dev This can be any random value.
        bytes32 salt = bytes32(0);

        /// @notice amount of time between scheduling the call and executing the call.
        /// @dev Must be >= minDelay
        uint256 delay = 2 days;

        // Get hash
        bytes32 id = timelockController.hashOperationBatch(targets, values, payloads, predecessor, salt);

        // Call Schedule
        vm.prank(address(222));
        timelockController.scheduleBatch(targets, values, payloads, predecessor, salt, delay);

        // Post-State check.
        assertEq(timelockController.getTimestamp(id), block.timestamp + delay);
    }

    function test_timelock_execute() public {

        address target = address(counter);
        uint256 value = 0;
        bytes4 selector = bytes4(keccak256("setNumber(uint256)"));
        bytes memory data = abi.encodeWithSelector(selector, 5);
        bytes32 predecessor = 0;
        bytes32 salt = bytes32(0);
        uint256 delay = 2 days;

        // Get hash
        bytes32 id = timelockController.hashOperation(target, value, data, predecessor, salt);

        // Pre-state check.
        assertEq(counter.number(), 0);

        // Call Schedule
        vm.prank(address(222));
        timelockController.schedule(target, value, data, predecessor, salt, delay);

        // Warp
        vm.warp(2 days + 1);

        // Call Execute
        vm.prank(address(222));
        timelockController.execute(target, value, data, predecessor, salt);

        // Post-State check.
        assertEq(counter.number(), 5);
    }

    function test_timelock_executeBatch() public {

        address[] memory targets = new address[](2);
        targets[0] = address(counter);
        targets[1] = address(counter);

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory payloads = new bytes[](2);
        bytes4 selector = bytes4(keccak256("setNumber(uint256)"));
        bytes memory data = abi.encodeWithSelector(selector, 5);
        payloads[0] = data;
        selector = bytes4(keccak256("addNumber(uint256)"));
        data = abi.encodeWithSelector(selector, 6);
        payloads[1] = data;

        bytes32 predecessor = 0;

        bytes32 salt = bytes32(0);

        uint256 delay = 2 days;

        // Get hash
        bytes32 id = timelockController.hashOperationBatch(targets, values, payloads, predecessor, salt);

        // Pre-state check.
        assertEq(counter.number(), 0);

        // Call Schedule
        vm.prank(address(222));
        timelockController.scheduleBatch(targets, values, payloads, predecessor, salt, delay);

        // Warp
        vm.warp(2 days + 1);

        // Call Execute
        vm.prank(address(222));
        timelockController.executeBatch(targets, values, payloads, predecessor, salt);

        // Post-State check.
        assertEq(counter.number(), 11);
    }

    
}
