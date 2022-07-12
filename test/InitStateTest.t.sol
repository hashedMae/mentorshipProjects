// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./InitState.t.sol";

contract InitStateTest is InitState {

    function testMint(uint256 x) public {
        x = bound(x, 1, 1e27);
        uint256 y = x * swap.y_0() / swap.x_0();
        uint256 xBal = iDAI.balanceOf(amuro);
        uint256 yBal = iWETH.balanceOf(amuro);
        uint256 z = x / swap.x_0();

        vm.startPrank(amuro);
        iDAI.approve(address(swap), 2**256-1);
        iWETH.approve(address(swap), 2**256-1);
        swap.addLiquidity(x);
        vm.stopPrank();
        assertEq(iDAI.balanceOf(amuro), xBal - x);
        assertEq(iWETH.balanceOf(amuro), yBal - y);
        assertEq(swap.balanceOf(amuro), z);
    }

    function testMintEmit(uint256 x) public {
        x = bound(x, 1, 1e27);
        uint256 y = x * swap.y_0() / swap.x_0();
        uint256 z = x / swap.x_0();

        vm.startPrank(gharma);
        iDAI.approve(address(swap), 2**256-1);
        iWETH.approve(address(swap), 2**256-1);
        vm.expectEmit(true, false, false, true);
        emit LiquidityProvided(gharma, x, y, z);
        swap.addLiquidity(x);
        vm.stopPrank();
    }

    function testRemoveLiquidity(uint256 z) public {
        uint256 xBal = iDAI.balanceOf(char);
        uint256 yBal = iWETH.balanceOf(char);
        uint256 zBal = swap.balanceOf(char);

        z = bound(z, 1, zBal);

        uint256 z_0 = swap.totalSupply();
        uint256 x_0 = swap.x_0();
        uint256 y_0 = swap.y_0();
        uint256 x = z / z_0 * x_0;
        uint256 y = z / z_0 * y_0;

        vm.prank(char);
        swap.removeLiquidity(z);

        assertEq(iDAI.balanceOf(char), xBal + x);
        assertEq(iWETH.balanceOf(char), yBal+ y);
        assertEq(swap.balanceOf(char), zBal - z);
    }

    function testRemoveLiquidityEmit(uint256 z) public {
        uint256 zBal = swap.balanceOf(char);
        z = bound(z, 1, zBal);

        uint256 z_0 = swap.totalSupply();
        uint256 x_0 = swap.x_0();
        uint256 y_0 = swap.y_0();

        uint256 x = z / z_0 * x_0;
        uint256 y = z / z_0 * y_0;

        vm.expectEmit(true, false, false, true);
        emit LiquidityRemoved(char, x, y, z);

        vm.prank(char);
        swap.removeLiquidity(z);
    }

    function testSwapX(uint256 x) public {
        x = bound(x, 1, swap.x_0());
        uint256 xBal = iDAI.balanceOf(amuro);
        uint256 yBal = iWETH.balanceOf(amuro);

        uint256 x_0 = swap.x_0();
        uint256 y_0 = swap.y_0();

        uint256 y = (x * y_0) / (x_0 + x);

        vm.startPrank(amuro);
        iDAI.approve(address(swap), x);
        swap.swapXForY(x);
        vm.stopPrank();

        assertEq(iDAI.balanceOf(amuro), xBal - x);
        assertEq(iWETH.balanceOf(amuro), yBal + y);
        assertEq(swap.x_0(), x_0 + x);
        assertEq(swap.y_0(), y_0 - y);
    }

    function testSwapXEmit(uint256 x) public {
        x = bound(x, 1, swap.x_0());

        uint256 x_0 = swap.x_0();
        uint256 y_0 = swap.y_0();

        uint256 y = (x * y_0) / (x_0 + x);

        vm.startPrank(amuro);
        iDAI.approve(address(swap), x);
        vm.expectEmit(true, false, false, true);
        emit Swap(amuro, x, 0, 0, y);
        swap.swapXForY(x);
        vm.stopPrank();
    }

    function testSwapY(uint256 y) public {
        y = bound(y, 1, swap.y_0());

        uint256 xBal = iDAI.balanceOf(gharma);
        uint256 yBal = iWETH.balanceOf(gharma);

        uint256 x_0 = swap.x_0();
        uint256 y_0 = swap.y_0();

        uint256 x = (y * x_0) / (y_0 + y);

        vm.startPrank(gharma);
        iWETH.approve(address(swap), y);
        swap.swapYForX(y);
        vm.stopPrank();

        assertEq(iDAI.balanceOf(gharma), xBal + x);
        assertEq(iWETH.balanceOf(gharma), yBal - y);
        assertEq(swap.x_0(), x_0 - x);
        assertEq(swap.y_0(), y_0 + y);
    }

    function testSwapYEmit(uint256 y) public {
        y = bound(y, 1, swap.y_0());

        uint256 x_0 = swap.x_0();
        uint256 y_0 = swap.y_0();

        uint256 x = (y * x_0) / (y_0 + y);

        vm.startPrank(gharma);
        iWETH.approve(address(swap), y);
        vm.expectEmit(true, false, false, true);
        emit Swap(gharma, 0, y, x, 0);
        swap.swapYForX(y);
        vm.stopPrank();
    }

    function testCannotSwapX0() public {
        vm.startPrank(amuro);
        vm.expectRevert("MechaSwap: Insufficient Tokens In");
        swap.swapXForY(0);
        vm.stopPrank();
    }

    function testCannotSwapY0() public {
        vm.expectRevert("MechaSwap: Insufficient Tokens In");
        vm.prank(gharma);
        swap.swapYForX(0);
    }
}