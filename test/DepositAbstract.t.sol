// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

abstract contract DepositAbstract is ZeroState {
     
     function setUp() public override virtual {
         super.setUp();
         
         vm.prank(sonic);
         rings.approve(address(vault), 1000);
         vm.prank(tails);
         rings.approve(address(vault), 1000);
         vm.prank(knuckles);
         rings.approve(address(vault), 1000);

     }
}