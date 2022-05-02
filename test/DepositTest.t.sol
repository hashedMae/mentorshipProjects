// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DepositAbstract.t.sol";
import "../lib/forge-std/src/Test.sol";

contract DepositTest is DepositAbstract {

    event Deposit(address indexed user, uint256 amount, uint256 balance);

    function testDepositBelowAllowance() public {
        vm.startPrank(sonic);
        rings.approve(address(vault), 100000);
        vault.depositToken(500);
        vm.stopPrank;
        assertEq(vault.userBalance(sonic), (500));
    }

    function testDepositEventEmit() public {
        vm.startPrank(tails);
        rings.approve(address(vault), 100000);
        vm.expectEmit(true, false, false, false);
        emit Deposit(tails, 100, 100);
        vault.depositToken(100);
        vm.stopPrank;
    }

    function testDepositUserBalanceUpdatesCorrectlyMultipleDeposits() public {
        vm.startPrank(sonic);
        rings.approve(address(vault), 100000);
        vault.depositToken(250);
        vault.depositToken(250);
        vm.stopPrank();
        assertEq(vault.userBalance(sonic), (500));

    }

    function testCannotDepositMoreThanInWallet() public {
        vm.prank(knuckles);
        vm.expectRevert("ERC20: Insufficient balance");
        vault.depositToken(5000);
    }

    function testDepositZeroTokens() public {
        vm.prank(knuckles);
        vault.depositToken(0);
    }
}