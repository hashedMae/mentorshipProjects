// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    event Wrapped(address indexed wrapper, uint amount);


    function testCannotUnwrapMoreTokensThanInWallet() public {
        vm.prank(sonic);
        vm.expectRevert("Not Enough WRings to unwrap");
        wrings.unwrap(10);
    }

    function testWrapTokens(uint64 amount) public {
        uint256 ringsPreBalance = rings.balanceOf(tails);
        uint256 wringsPreBalance = wrings.balanceOf(tails);
        vm.startPrank(tails);
        rings.approve(address(wrings), amount);
        wrings.wrap(amount);
        vm.stopPrank();
        uint256 ringsPostBalance = rings.balanceOf(tails);
        uint256 wringsPostBalance = wrings.balanceOf(tails);
        bool success = ringsPostBalance == (ringsPreBalance - amount) && wringsPostBalance == (wringsPreBalance + amount);
        assertEq(success, true);
        
    }

    function testWrapEventEmit(uint64 amount) public {
        vm.startPrank(knuckles);
        rings.approve(address(wrings), amount);
        vm.expectEmit(true, false, false, false);
        emit Wrapped(knuckles, amount);
        wrings.wrap(amount);
        vm.stopPrank;
    }
}