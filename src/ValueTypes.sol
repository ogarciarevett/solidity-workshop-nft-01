// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract ValueTypes {
    // Booleans
    bool public isActive = true;
    bool public isComplete;  // default: false
    
    // Integers
    uint256 public unsignedInt = 100;  // 0 to 2^256-1
    int256 public signedInt = -50;     // -2^255 to 2^255-1
    uint8 public smallUint = 255;      // 0 to 255
    uint16 public mediumUint = 65535;  // 0 to 65535
    
    // Address types
    address public userAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address payable public payableAddr;  // Can receive ETH
    
    // Fixed-size byte arrays
    bytes1 public singleByte = 0x41;           // 1 byte (ASCII 'A')
    bytes4 public fourBytes = 0x12345678;      // 4 bytes
    bytes32 public hash = keccak256("Hello");  // 32 bytes
    
    // Enums
    enum Status { 
        Pending,    // 0
        Active,     // 1
        Inactive    // 2
    }
    Status public currentStatus = Status.Active;
    
    // Demonstrate value type behavior
    function demonstrateValueTypes() public {
        // Value types are copied when assigned
        uint256 a = 100;
        uint256 b = a;  // b gets a copy of a's value
        b = 200;        // Changing b doesn't affect a
        assert(a == 100);  // a is still 100
        
        // Boolean operations
        bool result = isActive && !isComplete;
        
        // Type conversions
        uint8 small = 250;
        uint256 large = uint256(small);  // Explicit conversion
        
        // Address operations
        address recipient = address(0x123);
        payableAddr = payable(recipient);  // Convert to payable
    }
    
    // Demonstrate integer overflow/underflow (Solidity 0.8+ has automatic checks)
    function safeArithmetic() public pure returns (uint8) {
        uint8 max = type(uint8).max;  // 255
        // uint8 overflow = max + 1;  // This would revert!
        
        uint8 min = type(uint8).min;  // 0
        // uint8 underflow = min - 1;  // This would revert!
        
        return max;
    }
}