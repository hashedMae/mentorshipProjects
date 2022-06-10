// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DepositState.t.sol";

contract BorrowState is DepositState {

    function setUp() public virtual override {
        super.setUp();

        vm.prank(maverick);
        console.log("MAX BORROW", WMul.wmul(vault.Deposits(maverick, WETH), vault.daiWETH()));
        console.log("IS BORROWING", 100000e18);
        vault.borrowDAI(100000e18);
        vm.prank(phoenix);
        vault.borrowUSDC(100000e6);
        vm.startPrank(rooster);
        vault.borrowDAI (50000e18);
        vault.borrowUSDC(50000e6);
        vm.stopPrank();
    }
}