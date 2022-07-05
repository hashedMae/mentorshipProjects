// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BorrowState.t.sol";

contract BorrowStateTest is BorrowState {

    function testRepay(uint256 amount) public {
        amount = bound(amount, 1, 1e19);
        uint256 preBalance = iWETH.balanceOf(rickdom);
        uint256 preDebt = vault.Debt(rickdom);
        vm.startPrank(rickdom);
        iWETH.approve(address(vault), 2**256-1);
        vault.repay(amount);
        assertEq(iWETH.balanceOf(rickdom), preBalance - amount);
        assertEq(vault.Debt(rickdom), preDebt - amount);
    }

    function testRepayEmit(uint256 amount) public {
        amount = bound(amount, 1, 1e19);
        uint256 wad = vault.Debt(rickdom);
        vm.startPrank(rickdom);
        iWETH.approve(address(vault), 2**256-1);
        vm.expectEmit(true, false, false, true);
        emit Repay(rickdom, amount, wad - amount);
        vault.repay(amount);
    }

    function testWithdraw(uint256 amount) public {
        console.log("MAX ", vault.freeCollateral(zeong, USDC));
        uint256 max = vault.freeCollateral(zeong, USDC);
        amount = bound(amount, 1, max);
        uint256 preWallet = iUSDC.balanceOf(zeong);
        uint256 preDeposit = vault.Deposits(zeong, USDC);
        vm.prank(zeong);
        vault.withdraw(USDC, amount);
        assertEq(iUSDC.balanceOf(zeong), preWallet + amount);
        assertEq(vault.Deposits(zeong, USDC), preDeposit - amount);
    }
}