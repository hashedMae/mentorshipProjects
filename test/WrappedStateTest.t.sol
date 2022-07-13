// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./WrappedState.t.sol";

contract WrappedStateTest is WrappedState {

    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
 
    function testWithdrawTokens(uint256 assets) public {
        uint wBal = wrings.balanceOf(sonic);
        uint rBal = rings.balanceOf(sonic);
        
        
        uint256 maxAssets = _convertToAssets(wBal);

        assets = bound(assets, 1, maxAssets);

        uint256 shares = _convertToShares(assets);

        vm.prank(sonic);
        wrings.withdraw(assets, sonic, sonic);
        assertEq(rings.balanceOf(sonic), rBal + assets);
        assertEq(wrings.balanceOf(sonic), wBal - shares);
    }

    function testWithdrawEvent(uint256 assets) public {
        uint wBal = wrings.balanceOf(tails);
        
        uint256 maxAssets = _convertToAssets(wBal);

        assets = bound(assets, 1, maxAssets);

        uint256 shares = _convertToShares(assets);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(tails, tails, tails, assets, shares);
        vm.prank(tails);
        wrings.withdraw(assets, tails, tails);
    }

    function testRedeemTokens(uint256 shares) public {
        uint256 wBal = wrings.balanceOf(knuckles);
        uint256 rBal = rings.balanceOf(knuckles);

        shares = bound(shares, 1, wBal);

        
        uint256 assets = _convertToAssets(shares);

        
        vm.prank(knuckles);
        wrings.redeem(shares, knuckles, knuckles);
        
        assertEq(rings.balanceOf(knuckles), rBal + assets);
        assertEq(wrings.balanceOf(knuckles), wBal - shares);
    }

    function testRedeemEmit(uint256 shares) public {
        shares = bound(shares, 1, wrings.balanceOf(eggman));
        
        uint256 assets = _convertToAssets(shares);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(eggman, eggman, eggman, assets, shares);
        vm.prank(eggman);
        wrings.redeem(shares, eggman, eggman);
    }

    function testRedeemThreeParty(uint256 shares) public {
        uint256 wBal = wrings.balanceOf(eggman);
        uint256 rBal = rings.balanceOf(tails);

        shares = bound(shares, 1, wBal);

        uint256 assets = _convertToAssets(shares);

        vm.prank(eggman);
        rings.approve(sonic, 2**256-1);
        vm.prank(sonic);
        wrings.redeem(shares, tails, eggman);
        assertEq(wrings.balanceOf(eggman), wBal - shares);
        assertEq(rings.balanceOf(tails), rBal + assets);
    }
    
    function testRedeemThreePartyEmit(uint256 shares) public {
        shares = bound(shares, 1, wrings.balanceOf(eggman));
        
        uint256 assets = _convertToAssets(shares);

        vm.expectEmit(true, true, true, true);
        emit Withdraw(sonic, tails, eggman, assets, shares);
         vm.prank(eggman);
        rings.approve(sonic, 2**256-1);
        vm.prank(sonic);
        wrings.redeem(shares, tails, eggman);
    }
}