// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract InitState is ZeroState {

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(char);
        iDAI.approve(address(swap), 2**256-1);
        iWETH.approve(address(swap), 2**256-1);
        swap.init(1e27, 1e24);
        vm.stopPrank();
    }
}