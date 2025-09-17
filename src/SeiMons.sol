// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721A} from "./ERC721A.sol";
import {ISeiMons} from "./interfaces/ISeiMons.sol";

// Custom errors - MORE EFFICIENT
error InvalidMintQuantity();
error InsufficientPayment(uint256 required, uint256 provided);
error ExceedsMaxSupply(uint256 requested, uint256 available);

contract SeiMons is ERC721A, ISeiMons {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public constant PRICE_PER_TOKEN = 0.0001 ether;

    constructor() ERC721A("SeiMons", "SMON") {}

    function mint(uint256 quantity) internal virtual {
        _safeMint(msg.sender, quantity);
    }

    // Gas-efficient version with custom errors
    function mintWithCustomError(uint256 quantity) external payable {
        if (quantity == 0 || quantity > MAX_PER_MINT)
            revert InvalidMintQuantity();

        uint256 totalPrice = PRICE_PER_TOKEN * quantity;
        if (msg.value < totalPrice)
            revert InsufficientPayment(totalPrice, msg.value);

        if (totalSupply() + quantity > MAX_SUPPLY)
            revert ExceedsMaxSupply(totalSupply() + quantity, MAX_SUPPLY);

        // Saves ~2.5K gas on revert vs require strings
        mint(quantity);
    }

    // Less efficient version for comparison
    function mintWithRequire(uint256 quantity) external payable {
        require(quantity > 0 && quantity <= MAX_PER_MINT, "Invalid quantity");
        require(
            msg.value >= PRICE_PER_TOKEN * quantity,
            "Insufficient payment"
        );

        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds supply");
        mint(quantity);
        // Uses more gas, larger bytecode
    }
}
