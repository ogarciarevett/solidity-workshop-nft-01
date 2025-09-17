// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/Interfaces.sol";

contract InterfacesTest is Test {
    BasicToken public basicToken;
    DetailedToken public detailedToken;
    InterfaceConsumer public consumer;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    function setUp() public {
        // Deploy tokens
        basicToken = new BasicToken(1000000 * 10**18);
        detailedToken = new DetailedToken("Test Token", "TST", 18);
        
        // Deploy consumer with token addresses
        consumer = new InterfaceConsumer(address(basicToken), address(0));
        
        // Transfer some tokens to test accounts
        basicToken.transfer(user1, 1000 * 10**18);
        basicToken.transfer(user2, 500 * 10**18);
    }
    
    // ==================== INTERFACE IMPLEMENTATION TESTS ====================
    
    function test_BasicToken_ImplementsIERC20() public {
        // Test all IERC20 functions are implemented
        assertEq(basicToken.totalSupply(), 1000000 * 10**18);
        assertEq(basicToken.balanceOf(address(this)), 998500 * 10**18);
        assertEq(basicToken.balanceOf(user1), 1000 * 10**18);
    }
    
    function test_BasicToken_Transfer() public {
        vm.startPrank(user1);
        
        uint256 balanceBefore = basicToken.balanceOf(user2);
        bool success = basicToken.transfer(user2, 100 * 10**18);
        
        assertTrue(success);
        assertEq(basicToken.balanceOf(user1), 900 * 10**18);
        assertEq(basicToken.balanceOf(user2), balanceBefore + 100 * 10**18);
        
        vm.stopPrank();
    }
    
    function test_BasicToken_Approve() public {
        vm.startPrank(user1);
        
        bool success = basicToken.approve(user2, 500 * 10**18);
        assertTrue(success);
        
        assertEq(basicToken.allowance(user1, user2), 500 * 10**18);
        
        vm.stopPrank();
    }
    
    function test_BasicToken_TransferFrom() public {
        // User1 approves user2
        vm.prank(user1);
        basicToken.approve(user2, 200 * 10**18);
        
        // User2 transfers from user1
        vm.startPrank(user2);
        bool success = basicToken.transferFrom(user1, address(0x3), 150 * 10**18);
        
        assertTrue(success);
        assertEq(basicToken.balanceOf(user1), 850 * 10**18);
        assertEq(basicToken.balanceOf(address(0x3)), 150 * 10**18);
        assertEq(basicToken.allowance(user1, user2), 50 * 10**18);
        
        vm.stopPrank();
    }
    
    function test_DetailedToken_Metadata() public {
        assertEq(detailedToken.name(), "Test Token");
        assertEq(detailedToken.symbol(), "TST");
        assertEq(detailedToken.decimals(), 18);
    }
    
    // ==================== INTERFACE CONSUMER TESTS ====================
    
    function test_InterfaceConsumer_CheckBalance() public {
        uint256 balance = consumer.checkTokenBalance(user1);
        assertEq(balance, 1000 * 10**18);
    }
    
    function test_InterfaceConsumer_TransferTokens() public {
        // Transfer tokens to consumer contract
        basicToken.transfer(address(consumer), 100 * 10**18);
        
        // Consumer transfers tokens
        consumer.transferTokens(user2, 50 * 10**18);
        
        assertEq(basicToken.balanceOf(address(consumer)), 50 * 10**18);
        assertEq(basicToken.balanceOf(user2), 550 * 10**18);
    }
    
    function test_InterfaceConsumer_SupportsInterface() public {
        // Should support IERC20
        bool supportsERC20 = consumer.supportsInterface(address(basicToken));
        assertTrue(supportsERC20);
        
        // Random address should not support
        bool supportsRandom = consumer.supportsInterface(address(0x123));
        assertFalse(supportsRandom);
    }
    
    // ==================== INTERFACE CASTING TESTS ====================
    
    function test_InterfaceCasting() public {
        // Cast BasicToken to IERC20
        IERC20 token = IERC20(address(basicToken));
        
        // Should be able to call interface functions
        uint256 supply = token.totalSupply();
        assertEq(supply, 1000000 * 10**18);
        
        // Cast DetailedToken to IERC20Metadata
        IERC20Metadata metadata = IERC20Metadata(address(detailedToken));
        string memory name = metadata.name();
        assertEq(name, "Test Token");
    }
    
    // ==================== FUZZ TESTS ====================
    
    function testFuzz_Transfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount <= 1000 * 10**18);
        
        vm.startPrank(user1);
        
        uint256 balanceBefore = basicToken.balanceOf(to);
        bool success = basicToken.transfer(to, amount);
        
        assertTrue(success);
        assertEq(basicToken.balanceOf(user1), 1000 * 10**18 - amount);
        assertEq(basicToken.balanceOf(to), balanceBefore + amount);
        
        vm.stopPrank();
    }
    
    function testFuzz_Approve(address spender, uint256 amount) public {
        vm.assume(spender != address(0));
        
        vm.startPrank(user1);
        
        bool success = basicToken.approve(spender, amount);
        assertTrue(success);
        assertEq(basicToken.allowance(user1, spender), amount);
        
        vm.stopPrank();
    }
}