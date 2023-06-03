// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SoulBadge.sol";

contract CommitmentFactory {
    Soulbadge[] public soulbadges;
    event SoulBadgeCreated(address soulbadge);

    function createSoulbadge(
        string memory name,
        string memory symbol
    ) public returns (Soulbadge) {
        Soulbadge soulbadge = new Soulbadge(name, symbol);
        soulbadges.push(soulbadge);
        emit SoulBadgeCreated(address(soulbadge));
        return soulbadge;
    }

    function getSoulbadge(uint256 index) public view returns (Soulbadge) {
        return soulbadges[index];
    }

    function getSoulbadges() public view returns (Soulbadge[] memory) {
        return soulbadges;
    }
}
