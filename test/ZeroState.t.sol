// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Rings.sol";
import "src/WRings.sol";

abstract contract ZeroState is Test {
    
    Rings public rings;
    WRings public wrings;

    address sonic = address(0x1);
    address tails = address(0x2);
    address knuckles = address(0x3);

    address[] users = [sonic, tails, knuckles];
    
    function setUp() public virtual {
        rings = new Rings();
        wrings = new WRings(rings);

        for(uint i = 0; i < users.length; i++) {
            rings.mint(users[i], 1000*10**18);
            
        }
    }

    
}
