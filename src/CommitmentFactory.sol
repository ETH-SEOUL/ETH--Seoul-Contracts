// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Commitment.sol";

contract CommitmentFactory {
    Commitment[] public commitments;
    event CommitmentCreated(address commitment);

    function createCommitment() public returns (Commitment) {
        Commitment commitment = new Commitment();
        commitments.push(commitment);
        emit CommitmentCreated(address(commitment));
        return commitment;
    }

    function getCommitment(uint256 index) public view returns (Commitment) {
        return commitments[index];
    }

    function getCommitments() public view returns (Commitment[] memory) {
        return commitments;
    }
}
