// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";
import "../lib/forge-std/src/Test.sol";

contract DepositTest is ZeroState {

    event Deposit(address indexed user, uint256 amount, uint256 balance);

    function testDepositInitialBalance() public {
        vm.startPrank(sonic);
        rings.approve(address(vault), 100000);
        vault.deposit(500);
        vm.stopPrank;
        assertEq(vault.balances(sonic), (500));
    }

    function testDepositEventEmit() public {
        vm.startPrank(tails);
        rings.approve(address(vault), 100000);
        vm.expectEmit(true, false, false, false);
        emit Deposit(tails, 100, 100);
        vault.deposit(100);
        vm.stopPrank;
    }

    function testDepositUserBalanceUpdatesCorrectlyMultipleDeposits() public {
        vm.startPrank(sonic);
        rings.approve(address(vault), 100000);
        vault.deposit(250);
        vault.deposit(250);
        vm.stopPrank();
        assertEq(vault.balances(sonic), (500));

    }

    /** 
    function testCannotDepositMoreThanInWallet() public {
        vm.startPrank(knuckles);
        rings.approve(address(vault), 100000);
        vm.expectRevert("ERC20: Insufficient balance");
        vault.deposit(5000);
    } */

    function testDepositZeroTokens() public {
        vm.prank(knuckles);
        vault.deposit(0);
    }
}