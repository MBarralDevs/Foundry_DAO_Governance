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

    function setup() public {
        govToken = new GovToken(msg.sender);
        govToken.mint(USER, USER_STARTING_BALANCE);
    }
}
