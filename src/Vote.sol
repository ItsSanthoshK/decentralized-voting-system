//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Vote is Ownable {
    constructor() Ownable(msg.sender) {}

    // Error messages during election
    error CandidateAlreadyExists();
    error NoCandidatesAvailable();
    error AlreadyVoted();

    // Error messages for election timings
    error ElectionAlreadyStarted();
    error ElectionStillGoingOn();
    error ElectionNotStartedYet();
    error ElectionEnded();

    // Events
    event CandidateAdded(string name, string party);
    event Voted(address voter, string candidate);
    event WinnerDeclared(string name, uint256 votes);

    // Candidate Details struct
    struct Candidate {
        string name;
        string party;
        uint256 votes;
    }

    // Mappings
    mapping(bytes32 => Candidate) public idToCandidate;
    mapping(bytes32 => bool) public candidateExists;
    mapping(address => bool) public voted;

    // Arrays
    bytes32[] public listOfIds;

    // Vote timings variable
    uint public voteStart;
    uint public voteEnd;

    // Candidate Id is keccak256 combination of candidate's name and party
    function generateCandidateId(string memory _name, string memory _party) private pure returns (bytes32) {
        bytes32 ID = keccak256(abi.encodePacked(_name, _party));
        return ID;
    }

    // Only owner function to add the candidate !
    function addCandidate(string memory _name, string memory _party) external onlyOwner() {
        if(voteStart > 0) revert ElectionAlreadyStarted();                                  // REF:
        bytes32 id = generateCandidateId(_name, _party);                                         // Checking vote timings and candidate availability
        if(candidateExists[id]) revert CandidateAlreadyExists();

        listOfIds.push(id);
        idToCandidate[id] = Candidate({name: _name, party: _party, votes: 0});
        candidateExists[id] = true;

        emit CandidateAdded(_name, _party);
    }

    // NOTE:
    /* This is the trigger function for starting election !
     Use this function once all candidates are added and 
     confirm after this there's no way to start the election */
    function startVoting() external onlyOwner(){
        require(listOfIds.length > 2, "Add atleast 3 candidates to have a fair election !");
        voteStart = block.timestamp;
        voteEnd = block.timestamp + 3 days;
    }

    // List all the available candidates
    function getAllCandidates() external view returns(Candidate[] memory){
        if(listOfIds.length <= 0) revert NoCandidatesAvailable();

        Candidate[] memory candidates = new Candidate[](listOfIds.length);
        uint arrayLength = listOfIds.length;
        for(uint i=0; i<arrayLength; i++){
            candidates[i] = idToCandidate[listOfIds[i]];
        }

        return candidates;
    }

    // people can vote for their favourite candidate
    function voteFor(string memory _name, string memory _party) external canVoteTo(_name, _party) {

        if(voteStart == 0) revert ElectionNotStartedYet();
        if(block.timestamp > voteEnd) revert ElectionEnded();

        bytes32 id = generateCandidateId(_name, _party);
        idToCandidate[id].votes++;
        voted[msg.sender] = true;

        emit Voted(msg.sender, _name);
    }

    // to check the voter's voting status
    function hasVoted(address _voter) external view returns(bool){
        return voted[_voter];
    }

    // Functions to be used After Election is over to find and declare the winner!
    /* loops through all candidate and updates the max vote with highest vote and
     returns the candidate's name and votes he received */
     // NOTE: the tie event is yet to develop and will be available in future
    function getWinner() public view onlyOwner() returns (string memory, uint256) {

        if(0 == voteStart) revert ElectionNotStartedYet();
        if(block.timestamp < voteEnd) revert ElectionStillGoingOn();

        uint256 maxvotes = 0;
        bytes32 winnerId;
        uint arrayLength = listOfIds.length;

        for (uint256 i = 0; i < arrayLength; i++) {
            bytes32 id = listOfIds[i];
            uint256 votes = idToCandidate[id].votes;
            if (votes > maxvotes) {
                maxvotes = votes;
                winnerId = id;
            }
        }

        return (idToCandidate[winnerId].name, maxvotes);
    }

    function declareWinner() external onlyOwner {
        (string memory winner, uint256 votes) = getWinner();
        emit WinnerDeclared(winner, votes);
    }

    // To check whether the candidate exists and avoids voter voting twice
    modifier canVoteTo(string memory _name, string memory _party) {
        if(voted[msg.sender]) revert AlreadyVoted();
        if( ! (candidateExists[ generateCandidateId(_name, _party) ])) revert NoCandidatesAvailable();
        _;
    }
}