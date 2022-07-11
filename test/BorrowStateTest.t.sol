// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BorrowState.t.sol";

contract BorrowStateTest is BorrowState {
    
    using stdStorage for StdStorage;

    function testRepay(uint256 amount) public {
        amount = bound(amount, 1, 1e19);
        uint256 preBalance = WETH.balanceOf(rickdom);
        uint256 preDebt = vault.debt(rickdom);
        vm.startPrank(rickdom);
        WETH.approve(address(vault), 2**256-1);
        vault.repay(amount);
        assertEq(WETH.balanceOf(rickdom), preBalance - amount);
        assertEq(vault.debt(rickdom), preDebt - amount);
    }

    function testRepayEmit(uint256 amount) public {
        amount = bound(amount, 1, 1e19);
        uint256 wad = vault.debt(rickdom);
        vm.startPrank(rickdom);
        WETH.approve(address(vault), 2**256-1);
        vm.expectEmit(true, false, false, true);
        emit Repay(rickdom, amount, wad - amount);
        vault.repay(amount);
    }

    function testWithdraw(uint256 amount) public {
        console.log("MAX ", vault.freeCollateral(zeong, USDC));
        uint256 max = vault.freeCollateral(zeong, USDC);
        amount = bound(amount, 1, max);
        uint256 preWallet = USDC.balanceOf(zeong);
        uint256 preDeposit = vault.deposits(zeong, USDC);
        vm.prank(zeong);
        vault.withdraw(USDC, amount);
        assertEq(USDC.balanceOf(zeong), preWallet + amount);
        assertEq(vault.deposits(zeong, USDC), preDeposit - amount);
    }
    
    function testLiquidate() public {
        uint256 preWallet = USDC.balanceOf(rx78);
        stdstore
            .target(address(vault))
            .sig(vault.debt.selector)
            .with_key(zaku)
            .checked_write(1e18);
        stdstore
            .target(address(vault))
            .sig(vault.deposits.selector)
            .with_key(zaku)
            .with_key(address(USDC))
            .checked_write(6*10**7); 
        vm.prank(rx78);
        vault.liquidate(zaku); 
        assertEq(USDC.balanceOf(rx78), preWallet + 6*10**7);
    } 
}