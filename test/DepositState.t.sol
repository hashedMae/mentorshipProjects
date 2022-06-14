// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract DepositState is ZeroState {

    function setUp() public virtual override {

        super.setUp();

        vm.startPrank(maverick);
        iWETH.approve(address(vault), 2**256-1);
        vault.deposit(1000 ether);
        vm.stopPrank();
        
        vm.startPrank(phoenix);
        iWETH.approve(address(vault), 2**256-1);
        vault.deposit(1000 ether);
        vm.stopPrank();

        vm.startPrank(rooster);
        iWETH.approve(address(vault), 2**256-1);
        vault.deposit(1000 ether);
        vm.stopPrank();

        vm.startPrank(iceman);
        iDAI.approve(address(vault), 2**256-1);
        iUSDC.approve(address(vault), 2**256-1);
        ///vault.stableDeposit(1e30, 1e18);
        iDAI.transfer(address(vault), 1e30);
        iUSDC.transfer(address(vault), 1e18);
        vm.stopPrank();

        
        
    }
}