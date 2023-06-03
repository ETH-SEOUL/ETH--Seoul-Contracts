// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SoulbadgeFactory.sol";
import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";

contract Governance {
    /// @notice This contract aims to get the DAO members to vote on whether or not they would like to pass a certain soulbound token with given requirement details.

    //=========================================================================
    // State Variables
    using ByteHasher for bytes;

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The contract's external nullifier hash
    uint256 internal immutable externalNullifier;

    /// @dev The World ID group ID (always 1)
    uint256 internal immutable groupId = 1;

    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
    mapping(uint256 => bool) internal nullifierHashes;

    // address of soulbound factory
    address public soulboundFactory;

    struct Proposal {
        uint256 id;
        string description;
        address target;
        address contractAddress;
        string eventName;
        uint256 value;
        string[2] soulboundTokenDetails;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool ended;
        uint256 duration;
        string state;
    }

    mapping(address => mapping(uint256 => uint256)) public balances;
    mapping(address => mapping(uint256 => bool)) public voted;

    uint256 public totalStaked;

    Proposal[] public proposals;

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

    //=========================================================================
    // Constructor

    constructor(
        address _soulboundFactory,
        IWorldID _worldId,
        string memory _appId,
        string memory _actionId
    ) {
        soulboundFactory = _soulboundFactory;
        worldId = _worldId;
        externalNullifier = abi
            .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
            .hashToField();
    }

    //=========================================================================
    // Functions

    function createProposal(
        string memory _description,
        address _contractAddress,
        string memory _eventName,
        string[2] memory _soulboundTokenDetails,
        uint256 _duration
    ) public {
        proposals.push(
            Proposal({
                id: proposals.length,
                description: _description,
                duration: _duration,
                target: address(0),
                contractAddress: _contractAddress,
                eventName: _eventName,
                value: 0,
                soulboundTokenDetails: ["", ""],
                yesVotes: 0,
                noVotes: 0,
                executed: false,
                ended: false,
                state: ""
            })
        );

        emit ProposalCreated(proposals.length - 1, _description);
    }

    /// @param signal An arbitrary input from the user, usually the user's wallet address (check README for further details)
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demonstrates the claimer is registered with World ID (returned by the JS widget).
    /// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.
    function verifyVoter(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        // First, we make sure this person hasn't done this before
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        // We now verify the provided proof is valid and the user is verified by World ID
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );

        // We now record the user has done this, so they can't do it again (proof of uniqueness)
        nullifierHashes[nullifierHash] = true;
    }

    function vote(uint256 proposalId, bool support) public payable {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.ended, "Vote has ended.");
        require(!proposal.executed, "Proposal has already been executed.");
        require(!voted[msg.sender][proposalId], "You have already voted.");

        if (support) {
            proposal.yesVotes += 1;
        } else {
            proposal.noVotes += 1;
        }

        voted[msg.sender][proposalId] = true;
        balances[msg.sender][proposalId] += msg.value;
        address payable recipientAddress = payable(address(this)); // Replace with your desired address
        recipientAddress.transfer(msg.value);
        totalStaked += msg.value;
        emit VoteCasted(proposalId, msg.sender, support);
    }

    function withdraw(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.ended, "Vote has ended.");
        require(balances[msg.sender][proposalId] > 0, "You have no balance.");
        uint256 amount = balances[msg.sender][proposalId];
        if (amount > 0) {
            balances[msg.sender][proposalId] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function execute(uint256 proposalId) public {
        require(
            block.timestamp > proposals[proposalId].duration,
            "Vote has not ended yet."
        );
        require(
            proposals[proposalId].yesVotes > proposals[proposalId].noVotes,
            "Vote did not pass"
        );

        // Deploy the soulbound token using the remaining contract balance
        require(
            address(soulboundFactory).balance >= 1 ether,
            "Insufficient funds in the contract"
        );

        (bool success, ) = address(soulboundFactory).call{value: 1 ether}(
            abi.encodeWithSignature(
                "createSoulbadge(string,string)",
                proposals[proposalId].soulboundTokenDetails[0],
                proposals[proposalId].soulboundTokenDetails[1]
            )
        );
        require(success, "Failed to deploy soulbound token");

        proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId);
    }

    function getLatestUnusedProposalId() public view returns (uint256) {
        return proposals.length - 1;
    }
}
