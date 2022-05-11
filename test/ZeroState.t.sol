// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Rings.sol";
import "src/WRings.sol";
import "../lib/yield-utils-v2/contracts/math/WMul.sol";
import "../lib/yield-utils-v2/contracts/math/WDiv.sol";

abstract contract ZeroState is Test {
    
    Rings public rings;
    WRings public wrings;

    uint256 exchange = 438594385948594939584930593;

    address sonic = address(0x1);
    address tails = address(0x2);
    address knuckles = address(0x3);
    address eggman = address(0x4);

    address[] users = [sonic, tails, knuckles, eggman];
    
    function setUp() public virtual {
        rings = new Rings();
        wrings = new WRings(rings);

        
        
        wrings.setExchangeRate(exchange);

        for(uint i = 0; i < users.length; i++) {
            rings.mint(users[i], 100000000*10**18);
            
        }
    }

    
}
