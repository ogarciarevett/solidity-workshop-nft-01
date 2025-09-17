// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract DataLocations {
    // STATE VARIABLES (always in storage)
    string public storedText = "Stored in storage";
    uint256[] public storedArray = [1, 2, 3];
    
    struct User {
        string name;
        uint256 age;
    }
    User public storedUser = User("Alice", 30);
    
    mapping(address => User) public users;
    
    // Events for demonstration
    event DataProcessed(string location, uint256 gasUsed);
    
    // CALLDATA - read-only, external function parameters
    // Most gas efficient for external functions
    function processCalldata(string calldata _text, uint256[] calldata _numbers) 
        external 
        pure 
        returns (uint256, uint256) 
    {
        // _text cannot be modified
        // _text = "New text";  // ERROR: Cannot modify calldata
        
        // Can read from calldata
        uint256 textLength = bytes(_text).length;
        
        // Arrays in calldata
        uint256 sum = 0;
        for (uint256 i = 0; i < _numbers.length; i++) {
            sum += _numbers[i];
        }
        
        // Cannot modify calldata array
        // _numbers[0] = 100;  // ERROR: Cannot modify
        
        return (textLength, sum);
    }
    
    // MEMORY - temporary, modifiable, exists during function execution
    // More expensive than calldata but allows modifications
    function processMemory(string memory _text) 
        public 
        pure 
        returns (string memory) 
    {
        // Can create new variables in memory
        string memory prefix = "Modified: ";
        string memory newText = string.concat(prefix, _text);
        
        // Memory arrays can be created but are fixed size
        uint256[] memory tempArray = new uint256[](5);
        tempArray[0] = 100;
        tempArray[1] = 200;
        // tempArray.push(300);  // ERROR: Can't push to memory array
        
        // Structs in memory
        User memory tempUser = User("Bob", 25);
        tempUser.age = 26;  // Can modify memory struct
        
        return newText;
    }
    
    // STORAGE - persistent state, most expensive
    function updateStorage(string memory _newText) public {
        // Writing to storage is expensive
        storedText = _newText;
        
        // Modifying storage array
        storedArray.push(4);  // Can push to storage array
        storedArray[0] = 100;  // Modifying storage
        
        // Storage reference - points to actual storage
        User storage user = storedUser;
        user.age = 31;  // This modifies the stored user
    }
    
    // Demonstrate storage pointers
    function storagePointers() public {
        // Create storage reference to state variable
        uint256[] storage arrayPointer = storedArray;
        arrayPointer.push(999);  // Modifies the actual storedArray
        
        // Storage to memory copy (expensive)
        uint256[] memory memoryCopy = storedArray;  // Creates a copy in memory
        memoryCopy[0] = 500;  // Doesn't affect storedArray
        
        // Memory to storage assignment (replaces entire array)
        storedArray = memoryCopy;  // Replaces storage with memory copy
    }
    
    // Compare gas costs of different locations
    function compareGasCosts(string calldata calldataText) external {
        uint256 gasStart;
        
        // Test 1: Reading from calldata (cheapest)
        gasStart = gasleft();
        bytes calldata calldataBytes = bytes(calldataText);
        uint256 calldataLength = calldataBytes.length;
        emit DataProcessed("calldata", gasStart - gasleft());
        
        // Test 2: Copying to memory (more expensive)
        gasStart = gasleft();
        string memory memoryText = calldataText;  // Copy to memory
        bytes memory memoryBytes = bytes(memoryText);
        uint256 memoryLength = memoryBytes.length;
        emit DataProcessed("memory", gasStart - gasleft());
        
        // Test 3: Writing to storage (most expensive)
        gasStart = gasleft();
        storedText = calldataText;  // Write to storage
        emit DataProcessed("storage", gasStart - gasleft());
    }
    
    // Internal functions can use storage references
    function _modifyUser(User storage _user, string memory _newName) internal {
        // Direct modification of storage
        _user.name = _newName;  // Modifies the original storage location
    }
    
    // Example of using internal function with storage
    function updateUserName(address _userAddress, string memory _newName) public {
        User storage user = users[_userAddress];
        _modifyUser(user, _newName);  // Pass storage reference
    }
    
    // Best practices demonstration
    function bestPractices(
        uint256[] calldata _inputArray,  // Use calldata for read-only external data
        string memory _workingText       // Use memory when you need to modify
    ) external returns (string memory) {
        // Rule 1: Use calldata for external function inputs you won't modify
        uint256 sum = 0;
        for (uint256 i = 0; i < _inputArray.length; i++) {
            sum += _inputArray[i];
        }
        
        // Rule 2: Use memory for data you need to manipulate
        string memory result = string.concat(_workingText, " - Processed");
        
        // Rule 3: Use storage only when you need persistence
        if (sum > 100) {
            storedText = result;  // Only write to storage when necessary
        }
        
        // Rule 4: Use storage pointers to avoid copies
        User storage user = storedUser;  // Reference, not copy
        if (user.age < 50) {
            user.age++;  // Direct storage modification
        }
        
        return result;
    }
    
    // Stack variables (for simple types)
    function stackVariables() public pure returns (uint256) {
        // Simple types are stored on the stack (not a location keyword)
        uint256 x = 100;  // Stack
        uint256 y = 200;  // Stack
        bool flag = true;  // Stack
        address addr = address(0x123);  // Stack
        
        // Stack is cheapest for simple computations
        uint256 result = x + y;
        if (flag) {
            result *= 2;
        }
        
        return result;
    }
}