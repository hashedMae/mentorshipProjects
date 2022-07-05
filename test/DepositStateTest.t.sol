// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DepositState.t.sol";

contract DepositStateTest is DepositState {

    function testBorrow(uint256 amount) public {
        uint256 preWallet = iWETH.balanceOf(rickdom);
        uint256 preDebt = vault.Debt(rickdom);
        amount = bound(amount, 1, vault.borrowingPower(rickdom));
        vm.prank(rickdom);
        vault.borrow(amount);
        assertEq(vault.Debt(rickdom), preDebt + amount);
        assertEq(iWETH.balanceOf(rickdom), preWallet + amount);
    }


    function testBorrowEmit(uint256 amount) public {
        amount = bound(amount, 1, vault.borrowingPower(zeong));
        vm.expectEmit(true, false, false, true);
        emit Borrow(zeong, amount);
        vm.prank(zeong);
        vault.borrow(amount);
    }

}