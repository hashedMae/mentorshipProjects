// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BorrowState.t.sol";

contract BorrowStateTest is BorrowState {

    function testRepayDaiDebt(uint256 amount) public {
        amount = bound(amount, 1, vault.Debts(maverick, DAI));
        uint256 startBalance = iDAI.balanceOf(maverick);
        uint256 startDebt = vault.Debts(maverick, DAI);
        vm.startPrank(maverick);
        iDAI.approve(address(vault), 2**256-1);
        vault.repayDAI(amount);
        vm.stopPrank();
        assertEq(startDebt - amount, vault.Debts(maverick, DAI));
        assertEq(startBalance - amount, iDAI.balanceOf(maverick));
    }

    function testRepayUSDCDebt(uint256 amount) public {
        amount = bound(amount, 1, vault.Debts(phoenix, USDC));
        uint256 startBalance = iUSDC.balanceOf(maverick);
        uint256 startDebt = vault.Debts(phoenix, USDC);
        vm.startPrank(phoenix);
        iUSDC.approve(address(vault), 2**256-1);
        vault.repayUSDC(amount);
        vm.stopPrank();
        assertEq(startDebt - amount, vault.Debts(phoenix, USDC));
        assertEq(startBalance - amount, iUSDC.balanceOf(phoenix));
    }

    function testRepayBoth(uint256 amountDAI, uint256 amountUSDC) public {
        amountDAI = bound(amountDAI, 1, vault.Debts(rooster, DAI));
        amountUSDC = bound(amountUSDC, 1, vault.Debts(rooster, USDC));
        uint256 startDAIBalance = iDAI.balanceOf(rooster);
        uint256 startDAIDebt = vault.Debts(rooster, DAI);
        uint256 startUSDCBalance = iUSDC.balanceOf(rooster);
        uint256 startUSDCDebt = vault.Debts(rooster, USDC);
        vm.startPrank(rooster);
        iDAI.approve(address(vault), 2**256-1);
        iUSDC.approve(address(vault), 2**256-1);
        vault.repayDAI(amountDAI);
        vault.repayUSDC(amountUSDC);
        assertEq(startDAIDebt - amountDAI, vault.Debts(rooster, DAI));
        assertEq(startDAIBalance - amountDAI, iDAI.balanceOf(rooster));
        assertEq(startUSDCDebt - amountUSDC, vault.Debts(rooster, USDC));
        assertEq(startUSDCBalance - amountUSDC, iUSDC.balanceOf(rooster));
    }

    function testRepayDaiEmit(uint256 amount) public {
        amount = bound(amount, 1, vault.Debts(maverick, DAI));
        uint256 startDebt = vault.Debts(maverick, DAI);
        vm.expectEmit(true, false, false, true);
        emit Repay(maverick, amount, startDebt - amount);
        vm.startPrank(maverick);
        iDAI.approve(address(vault), 2**256-1);
        vault.repayDAI(amount);
    }

    function testRepayUSDCEmit(uint256 amount) public {
        uint256 startDebt = vault.Debts(phoenix, USDC);
        amount = bound(amount, 1, startDebt);
        vm.expectEmit(true, false, false, true);
        emit Repay(phoenix, amount, startDebt - amount);
        vm.startPrank(phoenix);
        iUSDC.approve(address(vault), 2**256-1);
        vault.repayUSDC(amount);
    }

    function testWithdrawWithDebt(uint256 amount) public {
        uint256 startWETH = iWETH.balanceOf(rooster);
        uint256 startDeposit = vault.Deposits(rooster, WETH);
        amount = bound(amount, 1, vault.Deposits(rooster, WETH) - vault.totalDebt(rooster));
        vm.prank(rooster);
        vault.withdraw(amount);
        assertEq(startWETH + amount, iWETH.balanceOf(rooster));
        assertEq(startDeposit - amount, vault.Deposits(rooster, WETH));
    }
}