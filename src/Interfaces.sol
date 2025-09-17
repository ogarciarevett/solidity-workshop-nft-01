// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// ==================== INTERFACE DEFINITIONS ====================

// Basic interface definition
interface IERC20 {
    // Events (optional but recommended in interfaces)
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // All functions are implicitly external and virtual
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    // Interfaces can have function signatures only, no implementation
    // function mint() external { }  // ERROR: No implementation allowed
}

// Extended interface (interface inheritance)
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// Interface for NFTs
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Custom interface for workshop
interface IWorkshopExample {
    // Structs can be defined in interfaces
    struct Workshop {
        string name;
        uint256 participants;
        bool isActive;
    }
    
    // Enums can also be defined in interfaces
    enum Status { Pending, Active, Completed }
    
    // Custom errors can be defined in interfaces (Solidity 0.8.4+)
    error WorkshopFull();
    error InvalidWorkshopId(uint256 id);
    
    // Function signatures
    function createWorkshop(string memory name) external returns (uint256);
    function joinWorkshop(uint256 workshopId) external;
    function getWorkshop(uint256 workshopId) external view returns (Workshop memory);
    function getStatus(uint256 workshopId) external view returns (Status);
}

// ==================== IMPLEMENTING INTERFACES ====================

// Contract implementing a single interface
contract BasicToken is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;
    }
    
    // Must implement all functions from the interface
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "Insufficient allowance");
        
        _allowances[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount);
        return true;
    }
    
    // Internal helper function (not part of interface)
    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "Insufficient balance");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}

// Contract implementing multiple interfaces
contract DetailedToken is IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    
    // IERC20Metadata functions
    function name() external view override returns (string memory) {
        return _name;
    }
    
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    
    // IERC20 functions (simplified implementation)
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) external override returns (bool) {
        // Implementation
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        // Implementation
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        // Implementation
        return true;
    }
}

// ==================== INTERFACE USAGE PATTERNS ====================

contract InterfaceConsumer {
    // Store reference to external contract via interface
    IERC20 public token;
    IERC721 public nft;
    
    constructor(address tokenAddress, address nftAddress) {
        token = IERC20(tokenAddress);
        nft = IERC721(nftAddress);
    }
    
    // Using interface to interact with external contracts
    function checkTokenBalance(address user) external view returns (uint256) {
        return token.balanceOf(user);
    }
    
    function transferTokens(address to, uint256 amount) external {
        // Interface ensures the contract has these functions
        bool success = token.transfer(to, amount);
        require(success, "Transfer failed");
    }
    
    // Type checking with interfaces
    function supportsInterface(address contractAddress) external view returns (bool) {
        // Check if contract implements specific interface
        // This is a simplified check - real implementation would use ERC165
        
        try IERC20(contractAddress).totalSupply() returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }
    
    // Interface casting
    function interactWithUnknown(address unknownContract) external {
        // Cast address to interface
        IERC20 unknownToken = IERC20(unknownContract);
        
        // Now we can call interface functions
        uint256 supply = unknownToken.totalSupply();
        require(supply > 0, "Invalid token");
    }
}

// ==================== ADVANCED INTERFACE PATTERNS ====================

// Diamond pattern interface (EIP-2535)
interface IDiamondCut {
    enum FacetCutAction { Add, Replace, Remove }
    
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    
    function diamondCut(FacetCut[] calldata cut, address init, bytes calldata data) external;
}

// Callback interface pattern
interface ICallback {
    function onTokenReceived(address from, uint256 amount, bytes calldata data) external returns (bytes4);
}

// Factory interface pattern
interface IFactory {
    function createContract(bytes calldata bytecode) external returns (address);
    function getDeployedContracts() external view returns (address[] memory);
}

// ==================== INTERFACE BEST PRACTICES ====================

contract InterfaceBestPractices {
    // 1. Use interfaces for external contract interactions
    IERC20 private immutable token;  // Immutable for gas optimization
    
    // 2. Version your interfaces
    // Use clear naming: IMyContractV1, IMyContractV2
    
    // 3. Keep interfaces minimal and focused
    // Split large interfaces into smaller ones
    
    // 4. Use interface inheritance for extensions
    // interface IExtended is IBase { }
    
    // 5. Define events and errors in interfaces
    // They're part of the contract's external API
    
    // 6. Use function overloading carefully
    // Some languages/tools may not support it well
    
    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Invalid address");
        token = IERC20(tokenAddress);
    }
    
    // 7. Always validate external contracts
    function safeInteraction() external view {
        // Check contract exists
        uint256 size;
        address tokenAddr = address(token);
        assembly {
            size := extcodesize(tokenAddr)
        }
        require(size > 0, "Contract not found");
        
        // Then interact
        uint256 balance = token.balanceOf(msg.sender);
    }
    
    // 8. Handle interface changes gracefully
    function checkCapabilities(address contractAddr) external view returns (bool hasMetadata) {
        // Try to cast to extended interface
        try IERC20Metadata(contractAddr).name() returns (string memory) {
            hasMetadata = true;
        } catch {
            hasMetadata = false;
        }
    }
}