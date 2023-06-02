// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

//=============================================================================
// Imports
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Governance is Ownable {
    //=========================================================================
    // State Variables

    struct Proposal {
        uint id;
        string description;
        address target;
        uint value;
        bytes data;
        uint voteCount;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(address => address) public delegates;
    uint public votingPeriod;

    //=========================================================================
    // Events

    event ProposalCreated(uint indexed id, string description);
    event VoteCasted(
        uint indexed proposalId,
        address indexed voter,
        bool support
    );
    event ProposalExecuted(uint indexed proposalId);

    //=========================================================================
    // Modifiers

    modifier onlyDelegate() {
        require(
            delegates[msg.sender] != address(0),
            "Only a delegate can perform this action"
        );
        _;
    }

    modifier proposalExists(uint proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist");
        _;
    }

    modifier canVote(uint proposalId) {
        require(
            !proposals[proposalId].executed,
            "Proposal has already been executed"
        );
        require(
            !proposals[proposalId].votes[msg.sender],
            "You have already voted on this proposal"
        );
        _;
    }

    //=========================================================================
    // Constructor

    constructor(uint _votingPeriod) {
        votingPeriod = _votingPeriod;
    }

    //=========================================================================
    // Functions

    function propose(
        string memory description,
        address target,
        uint value,
        bytes memory data
    ) public returns (uint proposalId) {
        proposalId = proposals.length;
        proposals.push(
            Proposal({
                id: proposalId,
                description: description,
                target: target,
                value: value,
                data: data,
                voteCount: 0,
                executed: false
            })
        );
        emit ProposalCreated(proposalId, description);
    }

    function vote(
        uint proposalId,
        bool support
    ) public proposalExists(proposalId) canVote(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        address voter = delegates[msg.sender];
        if (voter == address(0)) {
            voter = msg.sender;
        }
        proposal.votes[voter] = support;
        proposal.voteCount++;
        emit VoteCasted(proposalId, voter, support);
    }

    function getVoteWeight(
        address voter
    ) public view returns (uint voteWeight) {
        if (delegates[voter] != address(0)) {
            return getVoteWeight(delegates[voter]);
        }
        return 1;
    }

    function hasQuorum(
        uint proposalId
    ) public view proposalExists(proposalId) returns (bool hasQuorum) {
        uint totalVotes = proposals[proposalId].voteCount;
        return totalVotes * 2 > votingPeriod;
    }

    function executeProposal(
        uint proposalId
    ) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal has already been executed");
        require(hasQuorum(proposalId), "Proposal does not have quorum");

        // Deploy soulbound token contract here using the target, calldata, and value
        address soulboundToken = deploySoulboundToken(
            proposal.target,
            proposal.data,
            proposal.value
        );

        // Store the soulbound token contract address for future reference
        // ...

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function delegate(address delegatee) public {
        delegates[msg.sender] = delegatee;
    }

    function setVotingPeriod(uint newVotingPeriod) public {
        votingPeriod = newVotingPeriod;
    }

    //=========================================================================
    // View Functions

    function getProposalCount() public view returns (uint) {
        return proposals.length;
    }

    function getProposal(
        uint proposalId
    )
        public
        view
        proposalExists(proposalId)
        returns (
            string memory description,
            address target,
            uint value,
            bytes memory data,
            uint voteCount,
            bool executed
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.description,
            proposal.target,
            proposal.value,
            proposal.data,
            proposal.voteCount,
            proposal.executed
        );
    }

    //=========================================================================
    // Internal Functions

    function deploySoulboundToken(
        address target,
        bytes memory data,
        uint value
    ) internal returns (address) {
        // Deploy soulbound token contract using the target, calldata, and value
        // ...

        // Return the address of the deployed soulbound token contract
        return address(0); // Placeholder address for demonstration purposes
    }
}
