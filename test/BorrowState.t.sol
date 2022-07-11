// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DepositState.t.sol";

contract BorrowState is DepositState {

    function setUp() public virtual override {
        super.setUp();

        for(uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            vault.borrow(1e19);
        }
    }
}