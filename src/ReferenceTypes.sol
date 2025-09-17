// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract ReferenceTypes {
    // Dynamic arrays
    uint256[] public dynamicArray;
    string[] public names;
    
    // Fixed-size arrays
    uint256[5] public fixedArray = [1, 2, 3, 4, 5];
    address[3] public topUsers;
    
    // Strings
    string public name = "Alice";
    string public message = "Hello, Solidity!";
    
    // Dynamic bytes
    bytes public dynamicBytes = "Hello World";
    bytes public data;
    
    // Structs
    struct User {
        string name;
        uint256 age;
        address wallet;
        bool isActive;
    }
    
    User public defaultUser = User("Bob", 30, address(0x123), true);
    User[] public users;
    
    // Nested struct
    struct Company {
        string name;
        User ceo;
        uint256 employeeCount;
    }
    Company public company;
    
    // Mappings
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;  // Nested mapping
    mapping(uint256 => User) public userById;
    mapping(address => bool) public isRegistered;
    
    // Array of structs with mapping
    struct Token {
        string name;
        uint256 totalSupply;
        mapping(address => uint256) balances;
    }
    Token[] public tokens;  // Can't be public due to nested mapping
    
    // Constructor
    constructor() {
        // Initialize some data
        dynamicArray.push(100);
        dynamicArray.push(200);
        dynamicArray.push(300);
        
        users.push(User("Alice", 25, msg.sender, true));
        users.push(User("Charlie", 35, address(0x456), false));
    }
    
    // Demonstrate reference type behavior
    function demonstrateReferenceTypes() public {
        // Arrays
        uint256[] memory tempArray = new uint256[](3);
        tempArray[0] = 10;
        tempArray[1] = 20;
        tempArray[2] = 30;
        
        // Reference assignment (both point to same data in memory)
        uint256[] memory arrayRef = tempArray;
        arrayRef[0] = 999;
        assert(tempArray[0] == 999);  // Changed because they reference same data
        
        // Struct operations
        User memory newUser = User({
            name: "David",
            age: 40,
            wallet: address(0x789),
            isActive: true
        });
        users.push(newUser);
        
        // Storage reference
        User storage storageUser = users[0];
        storageUser.age = 26;  // This modifies the stored user directly
    }
    
    // Array operations
    function arrayOperations() public {
        // Push
        dynamicArray.push(400);
        
        // Pop (removes last element)
        if (dynamicArray.length > 0) {
            dynamicArray.pop();
        }
        
        // Delete (sets element to default value, doesn't change length)
        delete dynamicArray[0];  // Sets to 0
        
        // Length
        uint256 arrayLength = dynamicArray.length;
        
        // Create memory array (fixed size in memory)
        uint256[] memory memArray = new uint256[](5);
        // memArray.push(1);  // ERROR: Can't push to memory array
    }
    
    // String operations
    function stringOperations() public view returns (string memory) {
        // Concatenation
        string memory greeting = string.concat("Hello, ", name);
        
        // Comparison (must use keccak256)
        bool isEqual = keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Alice"));
        
        return greeting;
    }
    
    // Bytes operations
    function bytesOperations() public {
        // Bytes can be manipulated like arrays
        bytes memory b = "Hello";
        // b[0] = 0x48;  // Can't modify memory bytes directly
        
        // But storage bytes can be modified
        dynamicBytes.push(0x21);  // Add '!' to "Hello World"
        
        // Convert string to bytes and back
        string memory text = "Test";
        bytes memory textBytes = bytes(text);
        string memory backToString = string(textBytes);
    }
    
    // Mapping operations
    function mappingOperations() public {
        // Set values
        balances[msg.sender] = 1000;
        balances[address(0x123)] = 500;
        
        // Get value (returns 0 if not set)
        uint256 balance = balances[msg.sender];
        
        // Delete (resets to default value)
        delete balances[address(0x123)];
        
        // Nested mapping
        allowances[msg.sender][address(0x456)] = 100;
    }
}