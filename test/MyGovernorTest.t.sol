// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";

contract MyGovernorTest is Test {
    MyGovernor governor;
    GovToken govToken;
    TimeLock timeLock;
    Box box;

    address public USER = makeAddr("user");
    uint256 public constant USER_STARTING_BALANCE = 100 ether;
    uint256 public constant MIN_DELAY = 3600; // 1 hour, no one can execute the passed proposal until 1 hour after

    function setUp() public {
        //We need the govToken and TimeLock to deploy the governor
        govToken = new GovToken();
        govToken.mint(USER, USER_STARTING_BALANCE);

        vm.prank(USER);
        govToken.delegate(USER);
        timeLock = new TimeLock(MIN_DELAY, new address[](0), new address[](0));

        //We can now deploy the governor
        governor = new MyGovernor(govToken, timeLock);

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        //bytes32 adminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(governor));
        timeLock.grantRole(executorRole, address(0)); //address(0) is everyone

        //We need a contract to call through governance, so we deploy the Box contract
        box = new Box();
        //We need to transfer the ownership of the box contract to the timelock
        box.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }
}
