// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./WrappedState.t.sol";

contract WrappedStateTest is WrappedState {

    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    using CastU256U128 for uint256;
 
    function testWithdrawTokens(uint assets) public {
        uint wBal = wrings.balanceOf(sonic);
        uint rBal = rings.balanceOf(sonic);
        
        
        uint256 maxAssets = _convertToAssets(wBal);

        assets = bound(assets, 1, maxAssets);

        uint256 shares = _convertToShares(assets);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(sonic, sonic, sonic, assets, shares);
        vm.prank(sonic);
        uint256 value = wrings.withdraw(uint128(assets), sonic, sonic);
        assertEq(rings.balanceOf(sonic), rBal + assets);
        assertEq(wrings.balanceOf(sonic), wBal - shares);
        assertEq(value, shares);
    }

    function testRedeemTokens(uint256 shares) public {
        uint256 wBal = wrings.balanceOf(knuckles);
        uint256 rBal = rings.balanceOf(knuckles);

        shares = bound(shares, 1, wBal);

        
        uint256 assets = _convertToAssets(shares);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(knuckles, knuckles, knuckles, assets, shares);
        vm.prank(knuckles);
        uint256 value = wrings.redeem(uint128(shares), knuckles, knuckles);
        
        assertEq(rings.balanceOf(knuckles), rBal + assets);
        assertEq(wrings.balanceOf(knuckles), wBal - shares);
        assertEq(value, assets);
    }

    function testRedeemThreeParty(uint256 shares) public {
        uint256 wBal = wrings.balanceOf(eggman);
        uint256 rBal = rings.balanceOf(tails);

        shares = bound(shares, 1, wBal);

        uint256 assets = _convertToAssets(shares);

        vm.prank(eggman);
        rings.approve(sonic, 2**256-1);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(sonic, tails, eggman, assets, shares);
        vm.prank(sonic);
        wrings.redeem(uint128(shares), tails, eggman);
        assertEq(wrings.balanceOf(eggman), wBal - shares);
        assertEq(rings.balanceOf(tails), rBal + assets);
    }

    function testFlashLoan(uint256 amount) public {
        uint256 maxLoan = wrings.totalAssets();
        amount = bound(amount, 1, maxLoan);
        uint256 fee_ = wrings.flashFee(address(rings), amount);
        uint256 rBal = rings.balanceOf(address(borrower));

        vm.prank(bigTheCat);
        borrower.flashBorrow(address(rings), amount);

        assertEq(rings.balanceOf(address(borrower)), rBal - fee_);
    }
}