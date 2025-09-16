// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract DataTypes {
    // Booleans
    bool public isActive = true;

    // Integers
    uint256 public unsignedInt = 100; // 0 to 2^256-1
    int256 public signedInt = -50; // -2^255 to 2^255-1
    uint8 public smallUint = 255; // 0 to 255

    // Address
    address public userAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address payable public payableAddr; // Can receive ETH

    // Fixed-size byte arrays
    bytes32 public hash = keccak256("Hello"); // 32 bytes
    bytes1 public singleByte = 0x41; // 1 byte

    // Enums
    enum Status {
        Pending,
        Active,
        Inactive
    }
    Status public currentStatus = Status.Active;
}
