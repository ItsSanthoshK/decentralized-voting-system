// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vote} from "../src/Vote.sol";

contract TestVote is Test {
    event Voted(address voter, string candidate);
    event ElectionAborted(uint256 voteEnd);

    Vote public vote;
    string constant NAME = "sandy";
    string constant PARTY = "liberal";
    address USER = makeAddr("USER");

    function setUp() external returns (Vote) {
        vote = new Vote();
        return vote;
    }

    function testOnlyOwnerCanAddCandidate() external {
        vm.startPrank(USER);
        vm.expectRevert();
        vote.addCandidate(NAME, PARTY);
        vm.stopPrank();
    }

    function testOwnerCanAddCandidate() external {
        vm.startPrank(vote.owner());
        vote.addCandidate(NAME, PARTY);
        vm.stopPrank();
    }

    function testAddCandidateFailsAfterVotingStarts() external addMultipleCandidates {
        vote.startVoting();
        vm.expectRevert();
        vote.addCandidate(NAME, PARTY);
    }

    function testAddCandidateFailsIfSameCandidateAddedTwice() external {
        vote.addCandidate(NAME, PARTY);
        vm.expectRevert();
        vote.addCandidate(NAME, PARTY);
    }

    function testAddCandidateUpdatesTheStorage() external addCandidate {
        bytes32 candidateId = vote.generateCandidateId(NAME, PARTY);
        (string memory name, string memory party,) = vote.s_idToCandidate(candidateId);

        assertEq(vote.s_candidateExists(candidateId), true);
        assertEq(vote.s_listOfIds(0), candidateId);
        assertEq(name, NAME);
        assertEq(party, PARTY);
    }

    function testAddCandidateUpdatesTheStorageWithMultipleCandidates() external addMultipleCandidates {
        uint256 totalCandidates = vote.getListOfIdsArrayLength();
        for (uint256 i = 0; i < totalCandidates; i++) {
            string memory cName = string.concat("name", vm.toString(i));
            string memory cParty = string.concat("party", vm.toString(i));
            bytes32 candidateId = vote.generateCandidateId(cName, cParty);
            (string memory name, string memory party,) = vote.s_idToCandidate(candidateId);

            assertEq(vote.s_candidateExists(candidateId), true);
            assertEq(vote.s_listOfIds(i), candidateId);
            assertEq(name, cName);
            assertEq(party, cParty);
        }
    }

    function testStartVotingSuccess() external addMultipleCandidates {
        vote.startVoting();
        assertEq(vote.voteStart(), block.timestamp);
        assertEq(vote.voteEnd(), block.timestamp + 3 days);
    }

    function testStartVotingFails() external {
        vm.expectRevert();
        vote.startVoting();
    }

    function testVoteForACandidate() external addMultipleCandidates {
        vote.startVoting();

        (string memory cName, string memory cParty,) = vote.s_idToCandidate(vote.s_listOfIds(0));
        vm.prank(USER);
        vm.expectEmit();
        emit Voted(USER, cName);
        vote.voteFor(cName, cParty);
        assertEq(vote.hasVoted(USER), true);
    }

    function testVoteBeforeVotingStartFails() external addMultipleCandidates {
        (string memory cName, string memory cParty,) = vote.s_idToCandidate(vote.s_listOfIds(0));
        vm.expectRevert();
        vote.voteFor(cName, cParty);
    }

    // function testVoteAfterVotingEndsFails() external addMultipleCandidates {
    //     vote.startVoting();
    //     (string memory cName, string memory cParty,) = vote.s_idToCandidate(vote.s_listOfIds(0));

    //     uint voteEndedAt = block.timestamp;
    //     vm.expectEmit();
    //     emit ElectionAborted(voteEndedAt);
    //     vote.endVoting();

    //     vm.expectRevert();
    //     vote.voteFor(cName, cParty);
    // }

    modifier addCandidate() {
        vote.addCandidate(NAME, PARTY);
        _;
    }

    modifier addMultipleCandidates() {
        uint256 candidates = 5;
        for (uint256 i = 0; i < candidates; i++) {
            string memory cName = string.concat("name", vm.toString(i));
            string memory cParty = string.concat("party", vm.toString(i));
            vote.addCandidate(cName, cParty);
        }
        _;
    }
}
