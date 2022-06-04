// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./WrappedState.t.sol";

contract WrappedStateTest is WrappedState {

    event Unwrapped(address indexed unwrapper, uint256 amount);

    function testUnwrapTokens(uint64 amount) public {
        uint wringsPreBalance = wrings.balanceOf(sonic);
        uint ringsPreBalance = rings.balanceOf(sonic);
        vm.prank(sonic);
        wrings.unwrap(amount);
        uint wringsPostBalance = wrings.balanceOf(sonic);
        uint ringsPostBalance = rings.balanceOf(sonic);
        bool success = wringsPostBalance == (wringsPreBalance - amount) && ringsPostBalance == (ringsPreBalance + amount); 
        assertEq(success, true);
    }

    function testUnwrapEvent(uint64 amount) public {
        vm.expectEmit(true, false, false, true);
        emit Unwrapped(tails, amount);
        vm.prank(tails);
        wrings.unwrap(amount);
    }
}