// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "test/ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    function testDAIDebt(uint256 a) public {
        a = bound(a, 5527147e16, 70118025e15);
        uint256 p = vault.deposits(orson, WETH);
        p -= sDAI.swapForExactXPreview(a);

        vm.prank(orson);
        vault.borrowDAI(a);

        

        uint256 wBal = iWETH.balanceOf(jyn);
        ///vm.expectEmit(true, true, false, false);
        ///emit Liquidation(jyn, orson, a, p);
        vm.prank(jyn);
        liquid.liquidate(orson);
        assertGt(iWETH.balanceOf(jyn), wBal);
    }

    /***
    function testUSDCDebt(uint256 a) public {
        a = bound(a, 5527147e4, 78118025e3);

        vm.prank(orson);
        vault.borrowUSDC(a);

        uint256 wBal = iWETH.balanceOf(jyn);
        vm.expectEmit(true, true, false, false);
        emit Liquidation(jyn, orson, 0, 0, 0);
        vm.prank(jyn);
        uint256 pWETH = liquid.liquidate(orson);
        assertEq(iWETH.balanceOf(jyn), wBal + pWETH);
    }

    function testDualDebt(uint256 a, uint256 b) public {
        a = bound(a, 27735735e15,  390959012e14);
        b = bound(b, 27735735e3, 390959012e2);
        vm.startPrank(orson);
        vault.borrowDAI(a);
        vault.borrowUSDC(b);
        vm.stopPrank();

        uint256 wBal = iWETH.balanceOf(jyn);
        vm.expectEmit(true, true, false, false);
        emit Liquidation(jyn, orson, a, b, 0);
        vm.prank(jyn);
        uint256 pWETH = liquid.liquidate(orson);
        assertEq(iWETH.balanceOf(jyn), wBal + pWETH);
    } */
}