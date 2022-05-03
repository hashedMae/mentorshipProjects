/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

abstract contract DepositedState is ZeroState {

    function setUp() public override virtual {
        super.setUp();

        vm.startPrank(sonic);
        rings.approve(address(vault), 100000);
        vault.deposit(1000);
        vm.stopPrank();

        vm.startPrank(tails);
        rings.approve(address(vault), 100000);
        vault.deposit(1000);
        vm.stopPrank();

        vm.startPrank(knuckles);
        rings.approve(address(vault), 100000);
        vault.deposit(1000);
        vm.stopPrank();
        
    }
}