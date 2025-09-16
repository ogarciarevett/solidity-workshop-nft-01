// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error NotOwner();
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error PriceMustBeGreaterThanZero();
error NotNFTOwner(address sender, address nftAddress, uint256 tokenId);
error MarketplaceNotApproved(address nftAddress, uint256 tokenId);
error InsufficientPayment(uint256 required, uint256 sent);
error TransferFailed();
error RefundFailed();
error NotSeller(address sender, address nftAddress, uint256 tokenId);
error NoFeesToWithdraw();

/**
 * @title Seimon - ERC721A
 * @author 0xmar(@ogarciarevett)
 * @notice A basic Seimon to generate random NFTs.
 */
contract Seimon is ReentrancyGuard, AccessControl, Pausable {
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    constructor(uint256 feePercentage, address feeManager) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FEE_MANAGER_ROLE, feeManager);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
        feePercentage = feePercentage;
    }

    function generateRandomNFT(address nftAddress, uint256 tokenId) public {
        // TODO: Implement
    }
}
