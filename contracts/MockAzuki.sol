//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";

contract MockAzuki is ERC721A {
    uint256 constant public PRICE = 0.01 ether;
    uint256 constant public MAX_PER_TX = 5;

    constructor() ERC721A("MockAzuki", "MAZUKI") {}

    error NotEnoughPaid();
    error InvalidAmount();
    error NotEOA();

    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert NotEOA();
        }
        _;
    }

    function mint(uint256 quantity) external payable {
        if (quantity == 0 || quantity > MAX_PER_TX) {
            revert InvalidAmount();
        }
        
        refundIfOver(PRICE * quantity);

        _mint(msg.sender, quantity);
    }

    function guardedMint(uint256 quantity) external payable onlyEOA {
        if (quantity == 0 || quantity > MAX_PER_TX) {
            revert InvalidAmount();
        }
        
        refundIfOver(PRICE * quantity);

        _mint(msg.sender, quantity);
    }

    function refundIfOver(uint256 expected) private {
        if (msg.value < expected) {
            revert NotEnoughPaid();
            
        } else if (msg.value > expected) {
            payable(msg.sender).transfer(msg.value - expected);
        }
    }
}
