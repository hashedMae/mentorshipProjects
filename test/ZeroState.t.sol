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
    
    function setUp() public {
        rings = new Rings();
        wrings = new WRings(rings);

        rings.mint(sonic, 1000);
        rings.mint(tails, 1000);
        rings.mint(knuckles, 1000);
    }

    
}
