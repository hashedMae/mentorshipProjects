// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    function testCannotWithdrawZeroBalance() public {
        vm.prank(sonic);
        vm.expectRevert("requested amount exceeds user balance");
        vault.withdrawToken(1000);
    }

    function testCannotDepositZeroAllowance() public {
        vm.prank(tails);
        vm.expectRevert("ERC20: Insufficient approval");
        vault.depositToken(1000);
    }
}