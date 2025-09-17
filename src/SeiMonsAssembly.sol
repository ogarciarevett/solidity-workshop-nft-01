// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SeiMonsRandom} from "./SeiMonsRandom.sol";
import {ISeiMons} from "./interfaces/ISeiMons.sol";

// Custom errors for gas efficiency
error UnauthorizedCaller();

contract SeiMonsAssembly is SeiMonsRandom {
    // Mapping to store packed monster data (more gas efficient)
    mapping(uint256 => uint256) public packedMonsters;

    /*//////////////////////////////////////////////////////////////
                        ASSEMBLY COMMANDS REFERENCE
    //////////////////////////////////////////////////////////////*/

    // **mload** - Memory Load: Loads 32 bytes from memory at specified address
    // **add** - Addition: Adds two values together
    // **or** - Bitwise OR: Combines bits from two values (0x00FF | 0xFF00 = 0xFFFF)
    // **shl** - Shift Left: Shifts bits left by N positions (multiply by 2^N)
    // **shr** - Shift Right: Shifts bits right by N positions (divide by 2^N)
    // **and** - Bitwise AND: Masks bits (0xFFFF & 0x00FF = 0x00FF)
    // **calldataload** - Loads 32 bytes from calldata at specified offset
    // **mul** - Multiplication: Multiplies two values
    // **mstore** - Memory Store: Stores 32 bytes to memory at specified address
    // **lt** - Less Than: Returns 1 if a < b, else 0

    // Pack monster traits into single uint256 using assembly
    // Layout: [unused(152)][seed(32)][rarity(8)][speed(8)][defense(8)][attack(8)][hp(8)][secondaryType(8)][primaryType(8)]
    function packMonsterTraits(
        ISeiMons.Monster memory monster
    ) public pure returns (uint256 packed) {
        assembly {
            // Pack all traits into a single uint256
            // Monster struct memory layout:
            // 0x00: name (string pointer)
            // 0x20: primaryType
            // 0x40: secondaryType
            // 0x60: hp
            // 0x80: attack
            // 0xa0: defense
            // 0xc0: speed
            // 0xe0: rarity
            // 0x100: seed

            // MLOAD: Loads 32 bytes from memory
            // ADD: Calculates memory address (monster pointer + offset)
            // Example: mload(add(monster, 0x20)) reads 32 bytes at monster+32
            let primaryType := mload(add(monster, 0x20))
            let secondaryType := mload(add(monster, 0x40))
            let hp := mload(add(monster, 0x60))
            let attack := mload(add(monster, 0x80))
            let defense := mload(add(monster, 0xa0))
            let speed := mload(add(monster, 0xc0))
            let rarity := mload(add(monster, 0xe0))
            let seed := mload(add(monster, 0x100))

            // Pack: primaryType | (secondaryType << 8) | (hp << 16) | ...
            // SHL: Shifts bits left to position values at correct bit locations
            // OR: Combines shifted values into single uint256
            // Example: primaryType=5, secondaryType=3, hp=100
            // packed = 0x05 | 0x300 | 0x640000 = 0x640305
            packed := primaryType
            packed := or(packed, shl(8, secondaryType)) // Shift left 8 bits, OR with packed
            packed := or(packed, shl(16, hp)) // Shift left 16 bits, OR with packed
            packed := or(packed, shl(24, attack)) // Shift left 24 bits, OR with packed
            packed := or(packed, shl(32, defense)) // Shift left 32 bits, OR with packed
            packed := or(packed, shl(40, speed)) // Shift left 40 bits, OR with packed
            packed := or(packed, shl(48, rarity)) // Shift left 48 bits, OR with packed
            // Store lower 32 bits of seed in bits 56-87
            // AND: Masks seed to get only lower 32 bits (0xffffffff)
            packed := or(packed, shl(56, and(seed, 0xffffffff)))
        }
    }

    // Unpack monster traits from uint256 using assembly
    function unpackMonsterTraits(
        uint256 packed
    )
        public
        pure
        returns (
            uint8 primaryType,
            uint8 secondaryType,
            uint8 hp,
            uint8 attack,
            uint8 defense,
            uint8 speed,
            uint8 rarity,
            uint32 seedPart
        )
    {
        assembly {
            // Extract each value by shifting right and masking
            // AND: Masks to extract only the bits we want
            // SHR: Shifts bits right to move value to least significant position
            // Example: packed = 0x640305
            // primaryType = 0x640305 & 0xff = 0x05
            // secondaryType = (0x640305 >> 8) & 0xff = 0x03
            // hp = (0x640305 >> 16) & 0xff = 0x64 (100 in decimal)
            primaryType := and(packed, 0xff) // Extract bits 0-7
            secondaryType := and(shr(8, packed), 0xff) // Shift right 8, extract 8 bits
            hp := and(shr(16, packed), 0xff) // Shift right 16, extract 8 bits
            attack := and(shr(24, packed), 0xff) // Shift right 24, extract 8 bits
            defense := and(shr(32, packed), 0xff) // Shift right 32, extract 8 bits
            speed := and(shr(40, packed), 0xff) // Shift right 40, extract 8 bits
            rarity := and(shr(48, packed), 0xff) // Shift right 48, extract 8 bits
            seedPart := and(shr(56, packed), 0xffffffff) // Shift right 56, extract 32 bits
        }
    }

    // Store monster data in packed format (saves ~75% storage cost)
    function storePackedMonster(
        uint256 tokenId,
        ISeiMons.Monster memory monster
    ) external {
        if (msg.sender != address(this)) revert UnauthorizedCaller();
        packedMonsters[tokenId] = packMonsterTraits(monster);
    }

    // Calculate monster power using assembly (avoids memory allocation)
    function calculateMonsterPowerAssembly(
        uint256 packed
    ) public pure returns (uint256 power) {
        assembly {
            // Extract stats from packed data
            // SHR + AND: Standard pattern to extract specific bytes
            let hp := and(shr(16, packed), 0xff) // Extract hp from bits 16-23
            let attack := and(shr(24, packed), 0xff) // Extract attack from bits 24-31
            let defense := and(shr(32, packed), 0xff) // Extract defense from bits 32-39
            let speed := and(shr(40, packed), 0xff) // Extract speed from bits 40-47
            let rarity := and(shr(48, packed), 0xff) // Extract rarity from bits 48-55

            // Power = (hp + attack + defense + speed) * (rarity + 1)
            // ADD: Performs addition operations
            // MUL: Multiplies the sum by rarity multiplier
            // Nested ADD calls optimize gas by reducing stack operations
            power := mul(
                add(add(hp, attack), add(defense, speed)), // Sum all stats
                add(rarity, 1) // Rarity multiplier
            )
        }
    }

    // Regular Solidity version for comparison
    function calculateMonsterPowerSolidity(
        ISeiMons.Monster memory monster
    ) public pure returns (uint256) {
        return
            (uint256(monster.hp) +
                uint256(monster.attack) +
                uint256(monster.defense) +
                uint256(monster.speed)) * uint256(monster.rarity + 1);
    }

    // Optimized batch power calculation using assembly
    function batchCalculatePowerAssembly(
        uint256[] calldata packedData
    ) external pure returns (uint256[] memory powers) {
        assembly {
            // Get array length from calldata
            // .length accesses the length property of the calldata array
            let length := packedData.length

            // Allocate memory for return array
            // MLOAD 0x40: Loads the "free memory pointer" (tracks next free memory)
            // MSTORE: Stores value to memory address
            powers := mload(0x40) // Get free memory pointer
            mstore(powers, length) // Store array length at start
            let dataPtr := add(powers, 0x20) // Data starts after length (32 bytes)

            // Update free memory pointer
            // MUL: Calculate total bytes needed (length * 32 bytes per uint256)
            // ADD: Calculate new free memory location
            mstore(0x40, add(dataPtr, mul(length, 0x20)))

            // Process each packed monster
            // Assembly FOR loop syntax: for { init } condition { post } { body }
            for {
                let i := 0 // Initialize counter
            } lt(i, length) {
                // LT: Continue while i < length (lt returns 1 if true, 0 if false)
                i := add(i, 1) // Increment counter
            } {
                // CALLDATALOAD: Loads 32 bytes from calldata
                // packedData.offset: Starting position of array data in calldata
                // MUL(i, 0x20): Calculate offset for i-th element (i * 32 bytes)
                let packed := calldataload(add(packedData.offset, mul(i, 0x20)))

                // Extract stats and calculate power
                // Same extraction pattern as before
                let hp := and(shr(16, packed), 0xff)
                let attack := and(shr(24, packed), 0xff)
                let defense := and(shr(32, packed), 0xff)
                let speed := and(shr(40, packed), 0xff)
                let rarity := and(shr(48, packed), 0xff)

                // Calculate and store power
                let power := mul(
                    add(add(hp, attack), add(defense, speed)),
                    add(rarity, 1)
                )
                // MSTORE: Store result at correct position in memory array
                // ADD: Calculate memory address for i-th element
                mstore(add(dataPtr, mul(i, 0x20)), power)
            }
        }
    }

    // Regular batch calculation for comparison
    function batchCalculatePowerSolidity(
        ISeiMons.Monster[] memory monsters
    ) public pure returns (uint256[] memory powers) {
        powers = new uint256[](monsters.length);
        for (uint256 i = 0; i < monsters.length; i++) {
            powers[i] = calculateMonsterPowerSolidity(monsters[i]);
        }
    }

    // Ultra-optimized sum using assembly (no bounds checking, direct memory access)
    function sumArrayAssembly(
        uint256[] calldata values
    ) external pure returns (uint256 sum) {
        assembly {
            // Get array metadata from calldata
            let length := values.length // Get array length
            let dataPtr := values.offset // Get starting offset of array data in calldata

            // Loop through all values
            // This is more gas-efficient than Solidity because:
            // 1. No bounds checking on array access
            // 2. Direct calldata access (no memory copying)
            // 3. No overflow checks on addition
            for {
                let i := 0 // Initialize counter
            } lt(i, length) {
                // Continue while i < length
                i := add(i, 1) // Increment counter
            } {
                // CALLDATALOAD: Read value directly from calldata
                // ADD(dataPtr, MUL(i, 0x20)): Calculate position of i-th element
                // - dataPtr: Start of array data
                // - MUL(i, 0x20): Offset for i-th element (i * 32 bytes)
                // ADD(sum, ...): Add loaded value to running sum
                sum := add(sum, calldataload(add(dataPtr, mul(i, 0x20))))
            }
        }
    }

    // Regular sum for comparison
    function sumArraySolidity(
        uint256[] calldata values
    ) external pure returns (uint256 sum) {
        for (uint256 i = 0; i < values.length; i++) {
            sum += values[i];
        }
    }
}
