// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockAzuki} from "../../contracts/MockAzuki.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {ForwardRequest} from "../../contracts/libraries/ForwardRequest.sol";
import "../../lib/forge-std/src/console.sol";

abstract contract TestParameters {
}

contract MockAzukiTest is TestParameters, TestHelpers {
    MockAzuki public token;

    function setUp() public {
        token = new MockAzuki();

        vm.deal(user1, 100 ether);
    }

    function testTokenMint() public asPrankedUser(user1) {
        uint256 quantity = 3;

        token.mint{value: token.PRICE() * quantity}(quantity);
        
        assertEq(token.balanceOf(user1), quantity);
        assertEq(address(token).balance, token.PRICE() * quantity);
    }

    function testTokenMintWithLowLevelCall() public asPrankedUser(user1) {
        uint256 quantity = 5;
        bytes memory data = abi.encodeWithSelector(token.mint.selector, quantity);
        
        (bool success, ) = address(token).call{value: token.PRICE() * quantity}(data);

        assertEq(success, true);

        assertEq(token.balanceOf(user1), quantity);
    }
}
