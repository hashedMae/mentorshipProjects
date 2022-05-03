// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DepositedState.t.sol";

contract WithdrawTest is DepositedState {

    event Withdrawal(address indexed user, uint256 amount, uint256 balance);


    function testWithdrawExactBalance() public {
        vm.prank(sonic);
        vault.withdraw(1000);
        assertEq(vault.balances(sonic), 0);
    }

    function testWithdrawPartialBalance() public {
        vm.prank(tails);
        vault.withdraw(500);
        assertEq(vault.balances(tails), 500);
    }

    function testWithdrawEventEmit() public {
        vm.prank(knuckles);
        vm.expectEmit(true, false, false, false);
        emit Withdrawal(knuckles, 100, 900);
        vault.withdraw(100);
    }

    function testWithdrawZeroTokens() public {
        vm.prank(tails);
        vault.withdraw(0);
    }
}