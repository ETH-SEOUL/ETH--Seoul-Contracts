// SPDX-License-Identifier: MIT
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../src/Commitment.sol";

pragma solidity ^0.8.0;

contract CommitmentTest is Test {
    Commitment commitment;
    address alice = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function setUp() public {
        commitment = new Commitment();
        vm.startPrank(alice);
        commitment.beforeState(0, 0, 0);
        commitment.afterState(0, 0, 1);
    }

    function testVerify() public {
        console.log(
            commitment.verifyProof(
                [
                    "0x0ae3f261cd12f8625c74061a44e0253d7edc2aae5100eac0bce9ecefafa42b7d",
                    "0x09010a9ffd26a251463ed1f6b04bfcdd3f643f7fc98eac3a1cc81e194abeb82e"
                ],
                [
                    [
                        "0x2b289570780edd41f77139f77eb2db4431af43e89df2a971a4c505da3d95440f",
                        "0x18e56a2b6618e9edbdc14a0e3ea8b2b3b62f1d2b42d68897a69c31026b0b56d5"
                    ],
                    [
                        "0x235ab9d5b2a323694c6b924e32b26c25fb420c99cd646c7fa00ad9e7c26bacb5",
                        "0x0e36b1c218b9af9ec83bea083aac09158670b374c77277ff59bdce6fca197058"
                    ]
                ],
                [
                    "0x1c3661af592e45b67527ff7a7240253fb30b56ce3924026c59f1260d1821b977",
                    "0x144eca027500b93ee622d98d812ffb5e08cfbd6c797d56ca1504a390c5ece36c"
                ],
                [
                    "0x0000000000000000000000000000000000000000000000000000000000000001"
                ]
            )
        );
    }
}
