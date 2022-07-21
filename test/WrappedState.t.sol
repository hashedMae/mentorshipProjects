// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

abstract contract WrappedState is ZeroState {

    function setUp() public virtual override {
        super.setUp();

        for(uint i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            rings.approve(address(wrings), 2**256-1);
            wrings.deposit(1e26, users[i]);
            vm.stopPrank();
        }

    }
}