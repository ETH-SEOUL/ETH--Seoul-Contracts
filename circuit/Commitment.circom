pragma circom 2.1.2;

include "../circuit/node_modules/circomlib/circuits/poseidon.circom";
include "../circuit/node_modules/circomlib/circuits/comparators.circom";

template CommitmentScheme () {
    signal input beforeStateValue;
    signal input afterStateValue;

    signal output result;

    component gt = GreaterThan(32);

    gt.in[0] <== afterStateValue;
    gt.in[1] <== beforeStateValue;
    result <== gt.out;
}

component main = CommitmentScheme();
