// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MintTool} from "../../contracts/MintTool.sol";
import {MockAzuki} from "../../contracts/MockAzuki.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {ForwardRequest} from "../../contracts/libraries/ForwardRequest.sol";
import "../../lib/forge-std/src/console.sol";

abstract contract TestParameters {
    address internal _owner = address(99);
}

contract MintToolTest is TestParameters, TestHelpers {
    MintTool public tool;
    MockAzuki public token;

    function setUp() public asPrankedUser(user1) {
        tool = new MintTool(_owner);
        token = new MockAzuki();

        vm.deal(_owner, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testConstructor() public {
        assertEq(tool.creator(), user1);
        assertEq(tool.owner(), _owner);
    }

    function testExecuteWithUnauthorizedAddress() public {
        vm.prank(user2);

        ForwardRequest memory req = _getForwardRequest(5, token.mint.selector);

        vm.expectRevert(MintTool.NotAuthorizedToUse.selector);
        tool.executeWithSingleAddress{value: req.value}(req, 1);
    }

    function testGuardedMintExecuteWithSingleAddress() public asPrankedUser(_owner) {
        ForwardRequest memory req = _getForwardRequest(5, token.guardedMint.selector);

        (bool success) = tool.executeWithSingleAddress{value: req.value}(req, 1);

        // Fails as `guardedMint()` only allows EOAs
        assertEq(success, false);
        assertEq(token.balanceOf(address(tool)), 0);
    }

    function testMintExecuteWithSingleAddress() public asPrankedUser(user1) {
        uint256 quantity = 5;
        ForwardRequest memory req = _getForwardRequest(quantity, token.mint.selector);
        
        (bool success) = tool.executeWithSingleAddress{value: req.value}(req, 1);

        assertEq(success, true);
        assertEq(token.balanceOf(address(tool)), quantity);

        uint256[] memory ids = new uint256[](quantity - 1);
        for (uint256 i = 0; i < quantity - 1; i ++) {
            ids[i] = i;
        }

        tool.withdrawTokens(address(token), ids);

        assertEq(token.balanceOf(address(tool)), 1);
        assertEq(token.balanceOf(address(_owner)), quantity - 1);
    }

    function _getForwardRequest(uint256 quantity, bytes4 selector) internal returns (ForwardRequest memory req) {
        bytes memory data = abi.encodeWithSelector(selector, quantity);
        
        req = ForwardRequest({
            to: address(token),
            data: data,
            gas: 0.01 ether,
            value: token.PRICE() * quantity
        });
    }
}
