// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721A} from "./ERC721A.sol";

contract SimpleSeiMons is ERC721A {
    uint256 public constant PRICE = 0.0001 ether;
    uint256 public constant MAX_SUPPLY = 10000;

    constructor() ERC721A("SeiMons", "SMON") {}

    function mint(uint256 quantity) external payable {
        require(quantity > 0, "Invalid quantity");
        require(msg.value >= PRICE * quantity, "Insufficient payment");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds supply");

        _safeMint(msg.sender, quantity);
    }
}
