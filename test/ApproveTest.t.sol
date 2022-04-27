/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ApproveTest is ZeroState {

    function testApproval() public {
        vm.prank(sonic);
        rings.approve(address(vault), 500);
        assertEq(rings.allowance(sonic, address(vault)), 500); 
    }
}