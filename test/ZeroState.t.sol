// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "src/BasicVault.sol";
import "src/Rings.sol";

abstract contract ZeroState is Test {

    Rings public rings;
    BasicVault public vault;

    address sonic = address(0x1);
    address tails = address(0x2);
    address knuckles = address(0x3);

    

    function setUp() public virtual {
        rings = new Rings();
        vault = new BasicVault(rings);
        rings.mint(sonic, 1000);
        rings.mint(tails, 1000);
        rings.mint(knuckles, 1000);
    }
}
