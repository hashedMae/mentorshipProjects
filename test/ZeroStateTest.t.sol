// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    function testPoolInit(uint256 x, uint256 y) public {
        x = bound(x, 1e18, 1e24);
        y = bound(y, 1e9, 1e21);
        
        uint256 xBal = iDAI.balanceOf(char);
        uint256 yBal = iWETH.balanceOf(char);

        vm.startPrank(char);
        iDAI.approve(address(swap), 2**256-1);
        iWETH.approve(address(swap), 2**256-1);
        swap.init(x, y);
        vm.stopPrank();
        uint256 z = swap.balanceOf(char);
        assertEq(iDAI.balanceOf(char), xBal - x);
        assertEq(iWETH.balanceOf(char), yBal - y);
        assertEq(z, x*y);
    }

    function testInitEmit(uint256 x, uint256 y) public {
        x = bound(x, 1e18, 1e24);
        y = bound(y, 1e9, 1e21);

        vm.startPrank(char);
        iDAI.approve(address(swap), 2**256-1);
        iWETH.approve(address(swap), 2**256-1);
        vm.expectEmit(true, false, false, true);
        emit Init(char, x, y, x*y);
        swap.init(x, y);
        vm.stopPrank();
    }

    function testCannotLPBeforeInit(uint256 x) public {
        x = bound(x, 1e18, 1e24);

        vm.startPrank(amuro);
        iDAI.approve(address(swap), 2**256-1);
        iWETH.approve(address(swap), 2**256-1);
        vm.expectRevert("MechaSwap:Pool not intiated");
        swap.addLiquidity(x);
        vm.stopPrank();
    }

    function testCannotSwapXBeforeInit(uint256 x) public {
        x = bound(x, 1e18, 1e24);

        vm.startPrank(gharma);
        iDAI.approve(address(swap), 2**256-1);
        vm.expectRevert("MechaSwap:Pool not intiated");
        swap.swapXForY(x);
        vm.stopPrank();
    }

    function testCannotSwapYBeforeInit(uint256 y) public {
        y = bound(y, 1e9, 1e21);
        vm.startPrank(gharma);
        iWETH.approve(address(swap), 2**256-1);
        vm.expectRevert("MechaSwap:Pool not intiated");
        swap.swapYForX(y);
        vm.stopPrank();
    }
}