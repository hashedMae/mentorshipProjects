// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./WithdrawAbstract.t.sol";

contract WithdrawTest is WithdrawAbstract {

    event Withdrawal(address indexed user, uint256 amount, uint256 balance);


    function testWithdrawExactBalance() public {
        vm.prank(sonic);
        vault.withdrawToken(1000);
        assertEq(vault.userBalance(sonic), 0);
    }

    function testWithdrawPartialBalance() public {
        vm.prank(tails);
        vault.withdrawToken(500);
        assertEq(vault.userBalance(tails), 500);
    }

    function testWithdrawEventEmit() public {
        vm.prank(knuckles);
        vm.expectEmit(true, false, false, false);
        emit Withdrawal(knuckles, 100, 900);
        vault.withdrawToken(100);
    }

    function testWithdrawZeroTokens() public {
        vm.prank(tails);
        vault.withdrawToken(0);
    }

    function testCannot



}