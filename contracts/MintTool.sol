//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ForwardRequest} from "./libraries/ForwardRequest.sol";
import {IERC721} from "./interfaces/IERC721.sol";

contract MintTool {

    error NotEnoughPaid();
    error ZeroAmount();
    error NotAuthorizedToUse();

    address public owner; // Tool owner, who bought the tool
    address public creator;

    constructor(address _owner) {
        owner = _owner;
        creator = msg.sender;
    }

    modifier onlyOwnerOrCreator() {
        if (msg.sender != owner && msg.sender != creator) {
            revert NotAuthorizedToUse();
        }
        _;
    }

    function executeWithSingleAddress(ForwardRequest calldata req, uint256 numberOfCalls) external payable onlyOwnerOrCreator returns (bool) {
        if (numberOfCalls == 0) {
            revert ZeroAmount();
        }

        refundIfOver(numberOfCalls * req.value);

        for (uint256 i = 0; i < numberOfCalls; i ++) {
            (bool success, ) = _execute(req);

            if (!success) {
                // Finishes early to save gas
                return false;
            }
        }

        return true;
    }

    function executeWithDistributedContracts() external {
        // TODO: Create proxy contracts and distribute tokens to them
    }

    function _execute(ForwardRequest calldata req) internal returns (bool, bytes memory) {
        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            // abi.encodePacked(req.data, req.from)
            req.data
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }

    function withdrawTokens(address token, uint256[] memory ids) external {
        // TODO: Support ERC1155
        IERC721 tokenContract = IERC721(token);

        for (uint256 i = 0; i < ids.length; i ++) {
            tokenContract.transferFrom(address(this), owner, ids[i]);
        }
    }

    function refundIfOver(uint256 expected) private {
        if (msg.value < expected) {
            revert NotEnoughPaid();
            
        } else if (msg.value > expected) {
            payable(msg.sender).transfer(msg.value - expected);
        }
    }
}
