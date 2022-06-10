// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DepositState.t.sol";

contract DespositStateTest is DepositState {

    using stdStorage for StdStorage;

    function testborrowDAI(uint256 amount) public {
        amount = bound(amount, 1000, WMul.wmul(vault.Deposits(maverick, WETH), vault.daiWETH()));
        uint256 daiPreBalance = iDAI.balanceOf(maverick);
        vm.prank(maverick);
        vault.borrowDAI(amount);
        assertEq(daiPreBalance + amount, iDAI.balanceOf(maverick));
        assertEq(vault.Debts(maverick, DAI), amount);
    }

    function testBorrowUSDC(uint256 amount) public {
        amount = bound(amount, 1000, WMul.wmul(vault.Deposits(phoenix, WETH), vault.usdcWETH()));
        uint256 usdcPreBalance = iUSDC.balanceOf(phoenix);
        vm.prank(phoenix);
        vault.borrowUSDC(amount);
        assertEq(usdcPreBalance + amount, iUSDC.balanceOf(phoenix));
        assertEq(vault.Debts(phoenix, USDC), amount);
    }

    function testBorrowDAIEmit(uint256 amount) public {
        amount = bound(amount, 1000, WMul.wmul(vault.Deposits(maverick, WETH), vault.daiWETH()));
        vm.expectEmit(true, false, false, true);
        emit Borrow(maverick, amount);
        vm.prank(maverick);
        vault.borrowDAI(amount);
    }

    function testBorrowUSDCEmit(uint256 amount) public {
        amount = bound(amount, 1000, WMul.wmul(vault.Deposits(phoenix, WETH), vault.usdcWETH()));
        vm.expectEmit(true, false, false, true);
        emit Borrow(phoenix, amount);
        vm.prank(phoenix);
        vault.borrowUSDC(amount);
    }

    function testWithdrawWETH(uint256 amount) public {
        amount = bound(amount, 1, vault.Deposits(rooster, WETH));
        uint256 preBalance = iWETH.balanceOf(rooster);
        uint256 preDeposit = vault.Deposits(rooster, WETH);
        vm.prank(rooster);
        vault.withdraw(amount);
        assertEq(preBalance + amount, iWETH.balanceOf(rooster));
        assertEq(preDeposit - amount, vault.Deposits(rooster, WETH));
    }

    function testWithdrawWETHEmit(uint256 amount) public {
        amount = bound(amount, 1, vault.Deposits(rooster, WETH));
        vm.expectEmit(true, false, false, true);
        emit Withdraw(rooster, amount);
        vm.prank(rooster);
        vault.withdraw(amount);
    }

    function testLiquidateDAIDebt() public {
        uint256 debt= WMul.wmul(vault.Deposits(phoenix,DAI), vault.daiWETH()) + 1e18;
        stdstore
            .target(address(vault))
            .sig(vault.Debts.selector)
            .with_key(phoenix)
            .with_key(DAI)
            .checked_write(debt);
        console.log("PHOENIX DEBT AFTER MANIPULATION ", vault.Debts(phoenix, DAI));
        uint256 phoenixDeposit = vault.Deposits(phoenix, WETH);
        console.log("PHOENIX deposit BEFORE LIQUIDATION", phoenixDeposit);
        uint256 preBalance = iWETH.balanceOf(iceman);
        console.log("ICEMAN PREBALANCE", preBalance);
        vm.prank(iceman);
        vault.liquidate(phoenix); 
        console.log("SHOULD BE ZERO ", vault.Debts(phoenix, DAI));
        console.log("SHOULD BE ZERO ", vault.Deposits(phoenix, WETH));
        console.log("ICEMAN WETH AFTER LIQUIDATING", iWETH.balanceOf(iceman));
        assertEq(vault.Debts(phoenix, DAI), 0);
        assertEq(vault.Deposits(phoenix, WETH), 0);
        assertEq(preBalance + phoenixDeposit, iWETH.balanceOf(iceman)); 
    }

    function testLiquidateUSDC() public {
        uint256 debt= WMul.wmul(vault.Deposits(rooster,USDC), vault.usdcWETH()) + 1e6;
        stdstore 
            .target(address(vault))
            .sig(vault.Debts.selector)
            .with_key(rooster)
            .with_key(USDC)
            .checked_write(debt);
        uint256 roosterDeposit = vault.Deposits(rooster, WETH);
        uint256 preBalance = iWETH.balanceOf(iceman);
        vm.prank(iceman);
        vault.liquidate(rooster);
        assertEq(vault.Debts(rooster, USDC), 0);
        assertEq(vault.Deposits(rooster, WETH), 0);
        assertEq(preBalance + roosterDeposit, iWETH.balanceOf(iceman));
    }
}