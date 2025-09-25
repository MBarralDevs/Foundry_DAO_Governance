// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";

contract MyGovernorTest is Test {
    MyGovernor governor;
    GovToken govToken;
    TimeLock timeLock;
    Box box;

    uint256[] values;
    address[] targets;
    bytes[] calldatas;

    address public USER = makeAddr("user");
    uint256 public constant USER_STARTING_BALANCE = 100 ether;
    uint256 public constant MIN_DELAY = 3600; // 1 hour, no one can execute the passed proposal until 1 hour after
    uint256 public constant VOTING_DELAY = 1; // 1 block until proposal vote starts
    uint256 public constant VOTING_PERIOD = 50400; //How long voting last

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

    function testGovernanceUpdateBox() public {
        //Our goal is to call propose on the governor contract to call store(85) on the box contract
        uint256 valueToStore = 85;
        string memory description = "Store 85 in the Box";
        bytes memory callData = abi.encodeWithSelector(Box.store.selector, valueToStore);

        values.push(0);
        calldatas.push(callData);
        targets.push(address(box));

        //1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        //checking we are in pending state
        console2.log("Proposal State:", uint256(governor.state(proposalId))); //Pending, 0
        assertEq(uint256(governor.state(proposalId)), 0);

        //Move blocks forward to the voting delay
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        //checking we are in active state
        console2.log("Proposal State:", uint256(governor.state(proposalId))); //Active 1
        assertEq(uint256(governor.state(proposalId)), 1);

        //2. Vote the proposal
        string memory reason = "I found a reason to beeeeee";
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        //Move blocks forward to the voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        //checking we are in succeeded state
        console2.log("Proposal State:", uint256(governor.state(proposalId))); //Succeeded, 4
        assertEq(uint256(governor.state(proposalId)), 4);
    }
}
