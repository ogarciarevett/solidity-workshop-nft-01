// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract BytesComparison {
    // Fixed-size bytes (cheaper for known sizes)
    bytes1 public singleByte = 0x41;  // 'A' in ASCII
    bytes4 public fourBytes = 0x12345678;
    bytes32 public fixedBytes = "Hello";  // Padded with zeros to 32 bytes
    bytes32 public hashExample = keccak256("data");
    
    // Dynamic bytes (for variable length binary data)
    bytes public dynamicBytes = hex"0123456789abcdef";
    bytes public mutableBytes;
    
    // String (for text, UTF-8 encoded)
    string public text = "Hello World";
    string public unicodeText = unicode"Hello 🌍";  // UTF-8 encoded
    
    // Events for gas comparison
    event GasUsed(string operation, uint256 gasUsed);
    
    // Demonstrate bytes32 - fixed size, most efficient
    function demonstrateBytes32() public {
        // bytes32 is exactly 32 bytes, very gas efficient
        bytes32 data1 = "Short";  // Right-padded with zeros
        bytes32 data2 = bytes32(uint256(123));  // Convert number to bytes32
        
        // Efficient for hashes and identifiers
        bytes32 hash1 = keccak256("data");
        bytes32 hash2 = sha256("data");
        
        // Can be used as mapping keys (unlike dynamic bytes/string)
        // bytes32 can be used as mapping keys, but dynamic bytes/strings cannot
        // mapping(bytes32 => uint256) validMapping;  // Valid
        // mapping(bytes => uint256) invalidMapping;  // Invalid
        // mapping(string => uint256) invalidMapping2; // Invalid
        
        // Direct comparison (efficient)
        bool isEqual = (data1 == data2);
        
        // Bitwise operations
        bytes32 masked = data1 & bytes32(uint256(0xFF));
        bytes32 shifted = data1 >> 8;
    }
    
    // Demonstrate dynamic bytes - variable length
    function demonstrateDynamicBytes() public {
        // Create and modify bytes
        bytes memory data = new bytes(100);
        data[0] = 0x48;  // 'H'
        data[1] = 0x69;  // 'i'
        
        // Dynamic operations
        mutableBytes = hex"0123";
        mutableBytes.push(0x45);  // Add byte to storage bytes
        mutableBytes.pop();       // Remove last byte
        
        // Concatenation
        bytes memory combined = abi.encodePacked(hex"0123", hex"4567");
        
        // Length is dynamic
        uint256 length = mutableBytes.length;
        
        // Slice operations (using assembly)
        bytes memory slice = extractSlice(combined, 2, 2);
    }
    
    // Demonstrate string - for human-readable text
    function demonstrateString() public pure {
        // String operations
        string memory message = "Hello";
        string memory name = "World";
        
        // Concatenation (Solidity 0.8.12+)
        string memory greeting = string.concat(message, " ", name);
        
        // Cannot index strings directly
        // message[0];  // ERROR: Can't index string
        
        // Must convert to bytes for manipulation
        bytes memory messageBytes = bytes(message);
        messageBytes[0] = bytes1("h");  // Change 'H' to 'h'
        string memory modified = string(messageBytes);
        
        // Comparison must use hash
        bool isEqual = keccak256(bytes(message)) == keccak256(bytes("Hello"));
    }
    
    // Gas comparison between types
    function compareGasCosts() public {
        uint256 gasStart;
        
        // Test 1: bytes32 assignment (cheapest)
        gasStart = gasleft();
        bytes32 fixedData = "Test data here";
        emit GasUsed("bytes32 assignment", gasStart - gasleft());
        
        // Test 2: Dynamic bytes
        gasStart = gasleft();
        bytes memory dynamic = "Test data here";
        emit GasUsed("bytes memory assignment", gasStart - gasleft());
        
        // Test 3: String
        gasStart = gasleft();
        string memory str = "Test data here";
        emit GasUsed("string assignment", gasStart - gasleft());
        
        // Test 4: Storage write comparison
        gasStart = gasleft();
        fixedBytes = "New data";
        emit GasUsed("bytes32 storage write", gasStart - gasleft());
        
        gasStart = gasleft();
        dynamicBytes = "New data";
        emit GasUsed("bytes storage write", gasStart - gasleft());
        
        gasStart = gasleft();
        text = "New data";
        emit GasUsed("string storage write", gasStart - gasleft());
    }
    
    // Conversion examples
    function conversionExamples() public pure returns (
        bytes32,
        bytes memory,
        string memory
    ) {
        // String to bytes
        string memory originalText = "Hello";
        bytes memory textAsBytes = bytes(originalText);
        
        // Bytes to string
        string memory backToString = string(textAsBytes);
        
        // bytes to bytes32 (if <= 32 bytes)
        bytes memory shortBytes = "Short";
        bytes32 fixedFromDynamic;
        assembly {
            fixedFromDynamic := mload(add(shortBytes, 32))
        }
        
        // bytes32 to bytes
        bytes32 fixedStr = "Fixed string here";
        bytes memory dynamicFromFixed = abi.encodePacked(fixedStr);
        
        // Address to bytes
        address addr = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        bytes20 addrBytes = bytes20(addr);
        bytes memory addrAsDynamic = abi.encodePacked(addr);
        
        // Number to bytes
        uint256 number = 12345;
        bytes32 numberAsBytes = bytes32(number);
        bytes memory numberAsDynamic = abi.encodePacked(number);
        
        return (fixedFromDynamic, textAsBytes, backToString);
    }
    
    // Helper function to extract slice from bytes
    function extractSlice(
        bytes memory data,
        uint256 start,
        uint256 length
    ) public pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }
    
    // Practical use cases
    function practicalUseCases() public pure {
        // Use bytes32 for:
        // - Hashes and identifiers
        bytes32 userId = keccak256(abi.encodePacked("user", uint256(1)));
        // - Fixed-size data like Merkle tree nodes
        bytes32 merkleRoot = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;  
        // - Efficient storage of short strings (<= 32 bytes)
        bytes32 shortString = "CONSTANT_VALUE";
        
        // Use dynamic bytes for:
        // - Variable length binary data
        bytes memory signature = hex"0123456789abcdef";
        // - Raw data manipulation
        bytes memory rawData = new bytes(100);
        // - When you need array-like operations (push, pop, index)
        
        // Use string for:
        // - Human-readable text
        string memory userName = "Alice";
        // - UTF-8 encoded data
        string memory description = unicode"This is a description with émojis 🎉";
        // - Data that will be displayed to users
        string memory errorMessage = "Insufficient balance";
    }
    
    // Summary table representation in code
    function summaryAsCode() public pure returns (string memory) {
        // bytes32: Always 32 bytes, cheapest gas, use for hashes/IDs
        // bytes: Variable length, more expensive, use for binary data
        // string: Variable length, most expensive, use for text/UTF-8
        // calldata: Not a type but a location, cheapest for read-only external params
        
        return "See comments in code for comparison table";
    }
}