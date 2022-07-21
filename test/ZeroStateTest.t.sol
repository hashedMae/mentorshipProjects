// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {


    

    function testDeposit(uint256 amount) public {
        amount = bound(amount, 10000, 10000e18);

        uint256 preBalance = iWETH.balanceOf(maverick);

        vm.startPrank(maverick);
        iWETH.approve(address(vault), 10000e18);
        vault.deposit(amount);
        vm.stopPrank();
        
        assertEq(vault.Deposits(maverick, WETH), amount);
        assertEq(preBalance - amount, iWETH.balanceOf(maverick));
        assertEq(iWETH.balanceOf(address(vault)), amount);
    }

    function testDepositEmit(uint256 amount) public {
        amount = bound(amount, 10000, 10000e18);

        

        vm.startPrank(phoenix);
        iWETH.approve(address(vault), 10000e18);
        vm.expectEmit(true, false, false, true);
        emit Deposit(phoenix, amount);
        vault.deposit(amount);
        vm.stopPrank();
    }

    function testCannotBorrowDAIWithoutDeposit(uint256 amount) public {
        vm.assume(amount>1);
        vm.prank(rooster);
        vm.expectRevert("Insufficient collateral");
        
        vault.borrowDAI(amount);
    }

    function testCannotBorrowUSDCWithoutDeposit(uint256 amount) public {
        vm.assume(amount>1);
        vm.expectRevert("Insufficient collateral");
        vm.prank(iceman);
        vault.borrowUSDC(amount);
    }

    function testCannotWithdrawWETHWithoutBalance(uint256 amount) public {
        vm.assume(amount>1);
        vm.expectRevert("request exceeds available collateral");
        vm.prank(maverick);
        vault.withdraw(amount);
    }

    function testCannotRepayZeroDAIDebt(uint256 amount) public {
        vm.assume(amount>1);
        vm.expectRevert("payment exceeds debt");
        vm.prank(maverick);
        vault.repayDAI(amount);
    }

    function testCannotRepayZeroUSDCDebt(uint256 amount) public {
        vm.assume(amount>1);
        vm.expectRevert("payment exceeds debt");
        vm.prank(phoenix);
        vault.repayUSDC(amount);
    }

    

    

}

