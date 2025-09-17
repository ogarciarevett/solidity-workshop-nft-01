// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SeiMonsRandom} from "./SeiMonsRandom.sol";
import {ISeiMons} from "./interfaces/ISeiMons.sol";

// Custom errors for gas efficiency
error UnauthorizedCaller();

contract SeiMonsAssembly is SeiMonsRandom {
    // Mapping to store packed monster data (more gas efficient)
    mapping(uint256 => uint256) public packedMonsters;

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
            let primaryType := mload(add(monster, 0x20))
            let secondaryType := mload(add(monster, 0x40))
            let hp := mload(add(monster, 0x60))
            let attack := mload(add(monster, 0x80))
            let defense := mload(add(monster, 0xa0))
            let speed := mload(add(monster, 0xc0))
            let rarity := mload(add(monster, 0xe0))
            let seed := mload(add(monster, 0x100))

            // Pack: primaryType | (secondaryType << 8) | (hp << 16) | ...
            packed := primaryType
            packed := or(packed, shl(8, secondaryType))
            packed := or(packed, shl(16, hp))
            packed := or(packed, shl(24, attack))
            packed := or(packed, shl(32, defense))
            packed := or(packed, shl(40, speed))
            packed := or(packed, shl(48, rarity))
            // Store lower 32 bits of seed in bits 56-87
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
            primaryType := and(packed, 0xff)
            secondaryType := and(shr(8, packed), 0xff)
            hp := and(shr(16, packed), 0xff)
            attack := and(shr(24, packed), 0xff)
            defense := and(shr(32, packed), 0xff)
            speed := and(shr(40, packed), 0xff)
            rarity := and(shr(48, packed), 0xff)
            seedPart := and(shr(56, packed), 0xffffffff)
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
            let hp := and(shr(16, packed), 0xff)
            let attack := and(shr(24, packed), 0xff)
            let defense := and(shr(32, packed), 0xff)
            let speed := and(shr(40, packed), 0xff)
            let rarity := and(shr(48, packed), 0xff)

            // Power = (hp + attack + defense + speed) * (rarity + 1)
            power := mul(
                add(add(hp, attack), add(defense, speed)),
                add(rarity, 1)
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
            let length := packedData.length

            // Allocate memory for return array
            powers := mload(0x40)
            mstore(powers, length)
            let dataPtr := add(powers, 0x20)

            // Update free memory pointer
            mstore(0x40, add(dataPtr, mul(length, 0x20)))

            // Process each packed monster
            for {
                let i := 0
            } lt(i, length) {
                i := add(i, 1)
            } {
                // Load packed data from calldata
                let packed := calldataload(add(packedData.offset, mul(i, 0x20)))

                // Extract stats and calculate power
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
            let length := values.length
            let dataPtr := values.offset

            for {
                let i := 0
            } lt(i, length) {
                i := add(i, 1)
            } {
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
