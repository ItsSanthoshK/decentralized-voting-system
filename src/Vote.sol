//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Vote is Ownable {
    constructor() Ownable(msg.sender) {}

    // Error messages
    error CandidateAlreadyExists();

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

    mapping(bytes32 => Candidate) internal idToCandidate;
    mapping(address => bool) internal voted;
    bytes32[] public listOfIds;

    // Candidate Id is keccak256 combination of candidate's name and party
    function setCandidateId(string memory _name, string memory _party) private pure returns (bytes32) {
        bytes32 ID = keccak256(abi.encodePacked(_name, _party));
        return ID;
    }

    // Onlyowner function to add the candidate !
    function addCandidate(string memory _name, string memory _party) external onlyOwner() noDuplicateCandidate(_name, _party) {
        bytes32 id = setCandidateId(_name, _party);
        listOfIds.push(id);
        idToCandidate[id] = Candidate({name: _name, party: _party, votes: 0});
        emit CandidateAdded(_name, _party);
    }

    // people can vote for their favourite candidate
    function voteFor(string memory _name, string memory _party) external canVoteTo(_name, _party) {
        bytes32 id = setCandidateId(_name, _party);
        idToCandidate[id].votes++;
        voted[msg.sender] = true;
        emit Voted(msg.sender, _name);
    }

    // Functions to be used After Election is over to find the winner!

    function getWinner() public view onlyOwner() returns (string memory, uint256) {
        uint256 maxvotes = 0;
        bytes32 winnerId;
        for (uint256 i = 0; i < listOfIds.length; i++) {
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
        require(!voted[msg.sender], "You have already voted !");
        bytes32 id = setCandidateId(_name, _party);
        bool found = false;
        for (uint256 i = 0; i < listOfIds.length; i++) {
            if (id == listOfIds[i]) {
                found = true;
                break;
            }
        }
        require(found, "Please enter a valid candidate");
        _;
    }

    // To avoid adding same candidate twice
    modifier noDuplicateCandidate(string memory _name, string memory _party) {
        bytes32 id = setCandidateId(_name, _party);
        for(uint i=0; i<listOfIds.length; i++){
            if(id == listOfIds[i]){
                revert CandidateAlreadyExists();
            }
        }
        _;
    }
    
}
