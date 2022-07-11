// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./LiveState.t.sol";

contract LiveStateTest is LiveState {

    
    
    function testDeposit(uint256 amount) public {
        uint256 preWallet = WBTC.balanceOf(rickdom);
        uint256 preDeposit = vault.deposits(rickdom, WBTC);
        amount = bound(amount, 1, 1e19);
        vm.startPrank(rickdom);
        WBTC.approve(address(vault), 2**256-1);
        vault.deposit(WBTC, amount);
        vm.stopPrank;
        assertEq(vault.deposits(rickdom, WBTC), amount + preDeposit);
        assertEq(WBTC.balanceOf(rickdom), preWallet - amount);
    }

    function testDepositEmit(uint256 amount) public {
        amount = bound(amount, 1e9, 1e19);
        vm.startPrank(zeong);
        WBTC.approve(address(vault), 2**256-1);
        vm.expectEmit(true, true, false, true);
        emit Deposit(zeong, WBTC, amount);
        vault.deposit(WBTC, amount);
        vm.stopPrank;
    }

    function testCannotDepositUnapprovedToken(uint256 amount) public {
        vm.expectRevert("token not currently accepted as collateral");
        vm.prank(gelgoog);
        vault.deposit(WETH, amount);
    }

    function testCannotBorrowWithoutDeposit(uint256 amount) public {
        amount = bound(amount, 1, 1e21);
        vm.expectRevert("Insufficient collateral");
        vm.prank(gelgoog);
        vault.borrow(amount);
    }

}