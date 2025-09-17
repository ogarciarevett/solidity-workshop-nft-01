// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {SeiMons} from "../src/SeiMons.sol";
import {SeiMonsAssembly} from "../src/SeiMonsAssembly.sol";
import {SeiMonsRandom} from "../src/SeiMonsRandom.sol";

contract Deploy is Script {
    // Deployment addresses
    SeiMons public seiMons;
    SeiMonsAssembly public seiMonsAssembly;
    SeiMonsRandom public seiMonsRandom;

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy SeiMons (basic NFT with gas comparison functions)
        console.log("Deploying SeiMons...");
        seiMons = new SeiMons();
        console.log("SeiMons deployed at:", address(seiMons));

        // Deploy SeiMonsRandom (with random monster generation)
        console.log("Deploying SeiMonsRandom...");
        seiMonsRandom = new SeiMonsRandom();
        console.log("SeiMonsRandom deployed at:", address(seiMonsRandom));

        // Deploy SeiMonsAssembly (with assembly optimizations)
        console.log("Deploying SeiMonsAssembly...");
        seiMonsAssembly = new SeiMonsAssembly();
        console.log("SeiMonsAssembly deployed at:", address(seiMonsAssembly));

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Network: Sei Testnet (Chain ID: 1328)");
        console.log("SeiMons:", address(seiMons));
        console.log("SeiMonsRandom:", address(seiMonsRandom));
        console.log("SeiMonsAssembly:", address(seiMonsAssembly));
        console.log("\n=== DEPLOYMENT COMPLETE ===");
    }
}
