//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ForwardRequest} from "./libraries/ForwardRequest.sol";
import {MintTool} from "./MintTool.sol";
import {IMintTool} from "./interfaces/IMintTool.sol";

contract MintToolFactory {
    uint256 public constant FEE = 0.5 ether;
    address private immutable VAULT;

    mapping(address => address) public tools;

    error NotEnoughPaid();
    error NotPaidUser();

    constructor(address _vault) {
        VAULT = _vault;
    }

    function purchase() external payable {
        if (msg.value < FEE) {
            revert NotEnoughPaid();
        }

        tools[msg.sender] = _createMintTool(msg.sender);
        payable(VAULT).transfer(msg.value);
    }

    function _createMintTool(address user) internal returns (address) {
        MintTool tool = new MintTool(user);

        return address(tool);
    }

    function execute(ForwardRequest calldata req, uint256 numberOfCalls) external payable returns (bool) {
        address tool = tools[msg.sender];
        if (tool == address(0)) {
            revert NotPaidUser();
        }

        return IMintTool(tool).executeWithSingleAddress{value: msg.value}(req, numberOfCalls);
    }
}
