// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    using CastU256U128 for uint256;

    function testDepositTokens(uint256 assets) public {
        uint256 ringsPreBalance = rings.balanceOf(tails);
        uint256 wringsPreBalance = wrings.balanceOf(tails);
        assets = bound(assets, 1, ringsPreBalance);

        uint256 shares = _convertToShares(assets);


        vm.startPrank(tails);
        rings.approve(address(wrings), (2**256-1));
        vm.expectEmit(true, true, false, true);
        emit Deposit(tails, tails, assets, shares);
        uint256 value = wrings.deposit(uint128(assets), tails);
        vm.stopPrank();
        
        assertEq(rings.balanceOf(tails), ringsPreBalance - assets);
        assertEq(wrings.balanceOf(tails), wringsPreBalance + shares);
        assertEq(value, shares);
    }

    function testMintTokens(uint256 shares) public {
        uint256 rBal = rings.balanceOf(sonic);
        uint256 wBal = wrings.balanceOf(sonic);
        uint256 maxShares = _convertToShares(rBal);
        shares = bound(shares, 1, maxShares);
        
        uint256 assets = _convertToAssets(shares);

        vm.startPrank(sonic);
        rings.approve(address(wrings), (2**256-1));
        vm.expectEmit(true, true, false, true);
        emit Deposit(sonic, sonic, assets, shares);
        uint256 value = wrings.mint(uint128(shares), sonic);
        vm.stopPrank();

        assertEq(wrings.balanceOf(sonic), wBal + shares);
        assertEq(rings.balanceOf(sonic), rBal - assets);
        assertEq(value, assets);
    }
}