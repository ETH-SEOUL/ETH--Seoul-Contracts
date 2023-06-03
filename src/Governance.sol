// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DeploySoulbound.sol";

contract Governance {
    /// @notice This contract aims to get the DAO members to vote on whether or not they would like to pass a certain soulbound token with given requirement details.

    //=========================================================================
    // State Variables

    // address of soulbound factory
    address public soulboundFactory;

    //// @notice Store details related to the contract proposal
    /// @dev These are the details contained by the proposal struct
    /// @param id The id of the proposal
    /// @param description The description of the proposal
    /// @param target The address of the contract to be deployed
    /// @param value The amount of ether to be sent to the contract
    /// @param soulboundTokenDetails The details of the soulbound token to be deployed (name, symbol, etc.)
    /// @param voteCount The number of votes the proposal has received
    /// @param executed Whether or not the proposal has been executed

    struct Proposal {
        uint256 id;
        string description;
        address target;
        uint256 value;
        string[] soulboundTokenDetails;
        uint256 voteCount;
        bool executed;
        bool ended;
        uint256 duration;
    }

    /// @notice Store details related to the voter such as whether or not they have voted, their vote, and their weight
    struct Voter {
        mapping(uint256 => bool) voted; //this is a mapping of proposalId to bool
        mapping(uint256 => uint256) balances; //this is a mapping of proposalId to how much they deposited
    }

    /// @notice Cumulative staked amount
    uint256 public totalStaked;

    Proposal[] public proposals;
    mapping(address => Voter) public voters;

    //=========================================================================
    // Events and Errors

    event ProposalCreated(uint indexed id, string description);
    event VoteCasted(
        uint indexed proposalId,
        address indexed voter,
        bool support
    );
    event ProposalExecuted(uint indexed proposalId);

    /// The vote has already ended.
    error voteAlreadyEnded();
    /// The auction has not ended yet.
    error voteNotYetEnded();

    //=========================================================================
    // Modifiers

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

    constructor(address _soulboundFactory) {
        soulboundFactory = _soulboundFactory;
    }

    //=========================================================================
    // Functions

    /// @notice Create a new proposal
    /// @dev The arguments required to create a new proposal are
    /// @param _description The description of the proposal
    /// @param _target The address of the contract to be deployed
    /// @param _soulboundTokenDetails The details of the soulbound token to be deployed (name, symbol, etc.)
    /// @param _duration The duration of the vote in epoch
    function createProposal(
        string memory _description,
        address _target,
        string[] memory _soulboundTokenDetails,
        uint256 _duration
    ) public {
        proposals.push(
            Proposal({
                id: proposals.length,
                description: _description,
                duration: _duration,
                target: _target,
                value: 0,
                soulboundTokenDetails: _soulboundTokenDetails,
                voteCount: 0,
                executed: false,
                ended: false
            })
        );

        emit ProposalCreated(proposals.length - 1, _description);
    }

    /// @notice When the voter casts a vote, they have to pay some MATIC for the vote to go through
    function vote(uint256 proposalId, bool support) public payable {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.ended, "Vote has ended.");
        require(!proposal.executed, "Proposal has already been executed.");
        Voter storage sender = voters[msg.sender];
        require(!sender.voted[proposalId], "Already voted.");

        if (support) {
            proposal.voteCount += 1;
        } else {
            proposal.voteCount -= 1;
        }

        sender.voted = true;
        sender.balance += msg.value;
        emit VoteCasted(proposalId, msg.sender, support);
    }

    /// @notice Allow users to withdraw funds they sent along with the vote if the vote did not pass

    function withdraw(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        Voter storage sender = voters[msg.sender];
        require(proposal.ended, "Vote has not ended.");
        require(sender.balances[proposalId] > 0, "Nothing to withdraw.");
        uint256 amount = sender.balances[proposalId];
        if (amount > 0) {
            sender.balances[proposalId] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    // ends the vote
    // if DAO decided not to buy cupcakes members can withdraw deposited ether
    function EndVote(uint256 proposalId) public {
        require(block.timestamp > proposals[proposalId].duration);

        require(
            proposals[proposalId].voteCount > 0,
            "DAO decided to not buy cupcakes. Members may withdraw deposited ether."
        );

        (bool success, ) = address(soulboundFactory).call{value: 1 ether}(
            abi.encodeWithSignature(
                "createSoulbound(string[])",
                proposals[proposalId].soulboundTokenDetails
            )
        );
        require(success, "Failed to deploy soulbound token");
    }
}
