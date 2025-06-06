// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vote} from "../src/Vote.sol";

contract TestVote is Test{
    Vote vote = new Vote();
}