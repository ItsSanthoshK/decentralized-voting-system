# Decentralized Voting System

This is a smart contract for decentralized voting system written using solidity (foundry framework).

## Objective

> This is my hobby project. The main objective of this project is to make the election system to decentralize.

## Usage

To use this project, make sure you have foundry framework installed in your system. and run

```bash
forge install
```

before compiling because it runs on dependencies - openzeppelin and forge-std

## Code Explanation

- Once the code base is cloned and compiled, First and foremost , Before starting the election use addCandidate function to add the candidates to vote for
  

```solidity
function addCandidate(name, party){};
function generateCandidateId(name, party){};
```

- Next up start the election using start voting function, if startVoting function is not trigger, no can vote i.e consider election is still on hold !
  

```solidity
function startVoting(){};
```

- Then voters can vote to their candidate of liking and error handling are handled by modifiers
  

```solidity
function voteFor(name, party){};
```

- Winner is declare via getWinner and declareWinner functions
  

```solidity
function getWinner(){};
function declareWinner(){};
```

- Viewing functions can be used in frontend development
  

```solidity
function hasVoted(){};
function getWinner();
```

## License

This project is licensed under the MIT license - see the [LICENSE](./LICENSE) file for details.