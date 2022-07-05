// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./LiveState.t.sol";

contract LiveStateTest is LiveState {

    using stdStorage for StdStorage;
    
    function testDeposit(uint256 amount) public {
        uint256 preWallet = iWBTC.balanceOf(rickdom);
        uint256 preDeposit = vault.Deposits(rickdom, WBTC);
        amount = bound(amount, 1, 1e19);
        vm.startPrank(rickdom);
        iWBTC.approve(address(vault), 2**256-1);
        vault.deposit(WBTC, amount);
        vm.stopPrank;
        assertEq(vault.Deposits(rickdom, WBTC), amount + preDeposit);
        assertEq(iWBTC.balanceOf(rickdom), preWallet - amount);
    }

    function testDepositEmit(uint256 amount) public {
        amount = bound(amount, 1e9, 1e19);
        vm.startPrank(zeong);
        iWBTC.approve(address(vault), 2**256-1);
        vm.expectEmit(true, true, false, true);
        emit Deposit(zeong, WBTC, amount);
        vault.deposit(WBTC, amount);
        vm.stopPrank;
    }


    function testLiquidate() public {
        uint256 preWallet = iUSDC.balanceOf(rx78);
        stdstore
            .target(address(vault))
            .sig(vault.Debt.selector)
            .with_key(zaku)
            .checked_write(1*10**18);
        stdstore
            .target(address(vault))
            .sig(vault.Deposits.selector)
            .with_key(zaku)
            .with_key(USDC)
            .checked_write(60*10**6);
        vm.prank(rx78);
        vault.liquidate(zaku); 
        assertEq(iUSDC.balanceOf(rx78), preWallet + 6e7);
    }

    function testCannotDepositUnapprovedToken(uint256 amount) public {
        vm.expectRevert("token not currently accepted as collateral");
        vm.prank(gelgoog);
        vault.deposit(WETH, amount);
    }

    function testCannotBorrowWithoutDeposit(uint256 amount) public {
        amount = bound(amount, 1, 1e21);
        vm.expectRevert("Insufficient collateral");
        vm.prank(gelgoog);
        vault.borrow(amount);
    }

}