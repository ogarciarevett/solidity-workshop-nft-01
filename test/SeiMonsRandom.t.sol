// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {SeiMonsRandom} from "../src/SeiMonsRandom.sol";
import {ISeiMons} from "../src/interfaces/ISeiMons.sol";

contract SeiMonsRandomTest is Test {
    SeiMonsRandom seimons;
    address user = address(0x1234);

    function setUp() public {
        seimons = new SeiMonsRandom();
        vm.deal(user, 10 ether);
    }

    function testMintGeneratesRandomMonster() public {
        vm.prank(user);
        seimons.mintWithCustomError{value: 0.0001 ether}(1);

        ISeiMons.Monster memory monster = seimons.getMonster(0);

        // Verify monster has been generated
        assertTrue(
            bytes(monster.name).length > 0,
            "Monster should have a name"
        );
        assertTrue(monster.seed != 0, "Monster should have a seed");
        assertTrue(monster.rarity <= 4, "Rarity should be 0-4");

        console.log("Monster Name:", monster.name);
        console.log("Monster Rarity:", monster.rarity);
        console.log("Monster HP:", monster.hp);
        console.log("Monster Attack:", monster.attack);
        console.log("Monster Defense:", monster.defense);
        console.log("Monster Speed:", monster.speed);
    }

    function testMultipleMintsDifferentMonsters() public {
        vm.prank(user);
        seimons.mintWithCustomError{value: 0.0003 ether}(3);

        ISeiMons.Monster memory monster1 = seimons.getMonster(0);
        ISeiMons.Monster memory monster2 = seimons.getMonster(1);
        ISeiMons.Monster memory monster3 = seimons.getMonster(2);

        // Verify different seeds (should be different due to tokenId in hash)
        assertTrue(
            monster1.seed != monster2.seed,
            "Monsters should have different seeds"
        );
        assertTrue(
            monster2.seed != monster3.seed,
            "Monsters should have different seeds"
        );

        console.log("\n=== MINTED MONSTERS ===");
        console.log("Monster 1:", monster1.name, "Rarity:", monster1.rarity);
        console.log("Monster 2:", monster2.name, "Rarity:", monster2.rarity);
        console.log("Monster 3:", monster3.name, "Rarity:", monster3.rarity);
    }

    function testRarityDistribution() public {
        uint256[5] memory rarityCount;

        // Mint many monsters to check distribution
        for (uint i = 0; i < 100; i++) {
            vm.prank(user);
            vm.warp(block.timestamp + i); // Change timestamp for different randomness
            seimons.mintWithCustomError{value: 0.0001 ether}(1);

            ISeiMons.Monster memory monster = seimons.getMonster(i);
            rarityCount[monster.rarity]++;
        }

        console.log("\n=== RARITY DISTRIBUTION (100 monsters) ===");
        console.log("Common (50%):", rarityCount[0]);
        console.log("Uncommon (25%):", rarityCount[1]);
        console.log("Rare (15%):", rarityCount[2]);
        console.log("Epic (8%):", rarityCount[3]);
        console.log("Legendary (2%):", rarityCount[4]);

        // Check that we got at least some of each rarity (with 100 mints)
        // Note: This is probabilistic, so we don't assert exact percentages
        assertTrue(rarityCount[0] > 0, "Should have some common monsters");
        assertTrue(rarityCount[1] > 0, "Should have some uncommon monsters");
    }

    function testGetRarityName() public view {
        assertEq(seimons.getRarityName(0), "Common");
        assertEq(seimons.getRarityName(1), "Uncommon");
        assertEq(seimons.getRarityName(2), "Rare");
        assertEq(seimons.getRarityName(3), "Epic");
        assertEq(seimons.getRarityName(4), "Legendary");
    }

    function testGetElementName() public view {
        assertEq(seimons.getElementName(ISeiMons.ElementType.Fire), "Fire");
        assertEq(seimons.getElementName(ISeiMons.ElementType.Water), "Water");
        assertEq(seimons.getElementName(ISeiMons.ElementType.Grass), "Grass");
        assertEq(
            seimons.getElementName(ISeiMons.ElementType.Electric),
            "Electric"
        );
    }
}
