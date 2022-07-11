// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DepositState.t.sol";

contract DepositStateTest is DepositState {

    function testBorrow(uint256 amount) public {
        uint256 preWallet = WETH.balanceOf(rickdom);
        uint256 preDebt = vault.debt(rickdom);
        amount = bound(amount, 1, vault.remainingPower(rickdom));
        vm.prank(rickdom);
        vault.borrow(amount);
        assertEq(vault.debt(rickdom), preDebt + amount);
        assertEq(WETH.balanceOf(rickdom), preWallet + amount);
    }


    function testBorrowEmit(uint256 amount) public {
        amount = bound(amount, 1, vault.remainingPower(zeong));
        vm.expectEmit(true, false, false, true);
        emit Borrow(zeong, amount);
        vm.prank(zeong);
        vault.borrow(amount);
    }

}