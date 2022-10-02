//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ForwardRequest} from "../libraries/ForwardRequest.sol";

interface IMintTool {
    function executeWithSingleAddress(ForwardRequest calldata req, uint256 numberOfCalls) external payable returns (bool);
}
