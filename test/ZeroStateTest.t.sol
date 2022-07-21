// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    function testPoolInit(uint256 x, uint256 y) public {
        x = bound(x, 1, 1e24);
        y = bound(y, 1, 1e21);
        
        uint256 xBal = iDAI.balanceOf(char);
        uint256 yBal = iWETH.balanceOf(char);

        vm.startPrank(char);
        iDAI.approve(address(swap), 2**256-1);
        iWETH.approve(address(swap), 2**256-1);
        vm.expectEmit(true, false, false, true);
        emit LiquidityProvided(char, x, y, x*y);
        uint256 zVal = swap.init(x, y);
        vm.stopPrank();
        uint256 z = swap.balanceOf(char);
        assertEq(iDAI.balanceOf(char), xBal - x);
        assertEq(iWETH.balanceOf(char), yBal - y);
        assertEq(z, x*y);
        assertEq(zVal, x*y);
    }

    function testCannotInit0() public {
        vm.expectRevert("MechaSwap: Can't provide 0 tokens");
        vm.prank(char);
        swap.init(0,1);

    }

    function testCannotLPBeforeInit(uint256 x) public {
        x = bound(x, 1, 1e24);

        vm.startPrank(amuro);
        iDAI.approve(address(swap), 2**256-1);
        iWETH.approve(address(swap), 2**256-1);
        vm.expectRevert("MechaSwap:Pool not intiated");
        swap.addLiquidity(x);
        vm.stopPrank();
    }
}