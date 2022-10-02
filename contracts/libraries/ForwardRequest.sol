//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

struct ForwardRequest {
    // address from;
    address to;
    uint256 value;
    uint256 gas;
    // uint256 nonce;
    bytes data;
}
