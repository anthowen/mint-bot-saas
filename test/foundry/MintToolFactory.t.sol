// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MintToolFactory} from "../../contracts/MintToolFactory.sol";
import {MockAzuki} from "../../contracts/MockAzuki.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {ForwardRequest} from "../../contracts/libraries/ForwardRequest.sol";
import "../../lib/forge-std/src/console.sol";

abstract contract TestParameters {
    address internal _vault = address(100);
}

contract MintToolFactoryTest is TestParameters, TestHelpers {
    MintToolFactory public factory;
    MockAzuki public token;

    function setUp() public asPrankedUser(user1) {
        factory = new MintToolFactory(_vault);
        token = new MockAzuki();

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testPurchase() public asPrankedUser(user2) {
        assertTrue(factory.tools(user2) == address(0));

        factory.purchase{value: factory.FEE()}();

        assertFalse(factory.tools(user2) == address(0));
        assertEq(address(_vault).balance, factory.FEE());
    }

    function testMintExecuteWithSingleAddress() public asPrankedUser(user2) {
        uint256 quantity = 5;
        uint256 numOfCalls = 2;

        bytes memory data = abi.encodeWithSelector(token.mint.selector, quantity);
        ForwardRequest memory req = ForwardRequest({
            to: address(token),
            data: data,
            gas: 0.01 ether,
            value: token.PRICE() * quantity
        });

        factory.purchase{value: factory.FEE()}();

        (bool success) = factory.execute{value: req.value * numOfCalls}(req, numOfCalls);

        assertEq(success, true);
        assertEq(token.balanceOf(address(factory.tools(user2))), quantity * numOfCalls);
    }
}
