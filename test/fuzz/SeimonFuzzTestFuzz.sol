// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Seimon} from "contracts/Seimon.sol";
import {MockNFT} from "contracts/mocks/MockNFT.sol";

contract SeimonFuzzTest {
    Seimon internal _seimon;
    MockNFT internal _nft;
    uint256 internal constant _TOKEN_ID = 0; // First minted token will have ID 0
    uint256 internal constant _PRICE = 1 ether;
    uint256 internal constant _FEE_PERCENTAGE = 10;

    constructor() {
        address feeManager = address(this);
        _seimon = new Seimon(_FEE_PERCENTAGE, feeManager);
        _nft = new MockNFT();

        // Mint NFT directly to this contract so it can test listing/canceling
        _nft.mint(address(this));
    }

    function echidnaGenerateRandomNFT() public {
        // This contract owns the NFT and can approve and list it
        _nft.approve(address(_seimon), _TOKEN_ID);

        _seimon.generateRandomNFT(address(_nft), _TOKEN_ID);

        // (address seller, ) = _seimon.listings(address(_nft), TOKEN_ID);
        // assert(seller == address(this));

        _seimon.generateRandomNFT(address(_nft), _TOKEN_ID);

        // (seller, ) = _seimon.listings(address(_nft), TOKEN_ID);
        // assert(seller == address(0));
    }
} 