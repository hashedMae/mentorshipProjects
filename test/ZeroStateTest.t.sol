// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    event Wrapped(address indexed wrapper, uint256 amount);


    function testCannotUnwrapZeroTokens() public {
        vm.prank(sonic);
        vm.expectRevert("ERC20: Insufficient balance");
        wrings.unwrap(10);
    }

    function testWrapHalfOfTokens() public {
        vm.startPrank(tails);
        rings.approve(address(wrings), 500);
        wrings.wrap(500);
        vm.stopPrank();
        assertEq(wrings.balanceOf(tails), 500);
    }

    function testWrapEventEmit() public {
        vm.startPrank(knuckles);
        rings.approve(address(wrings), 1000);
        vm.expectEmit(true, false, false, false);
        emit Wrapped(knuckles, 1000);
        wrings.wrap(1000);
        vm.stopPrank;
    }
}