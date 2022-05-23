// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./WrappedState.t.sol";

contract WrappedStateTest is WrappedState {

    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
 
    function testWithdrawTokens(uint256 assets) public {
        uint wringsPreBalance = wrings.balanceOf(sonic);
        uint ringsPreBalance = rings.balanceOf(sonic);
        uint256 maxAssets = wrings.convertToAssets(wringsPreBalance);
        vm.assume(assets >= 1 && assets <= maxAssets);
        vm.prank(sonic);
        wrings.withdraw(assets, sonic, sonic);
        uint wringsPostBalance = wrings.balanceOf(sonic);
        uint ringsPostBalance = rings.balanceOf(sonic);
        bool success = wringsPostBalance == (wringsPreBalance - wrings.convertToShares(assets)) && ringsPostBalance == (ringsPreBalance + assets); 
        assertEq(success, true);
    }

    function testWithdrawEvent(uint256 assets) public {
        uint wringsPreBalance = wrings.balanceOf(tails);
        uint256 maxAssets = wrings.convertToAssets(wringsPreBalance);
        vm.assume(assets >= 1 && assets <= maxAssets);
        uint256 shares = wrings.convertToShares(assets);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(tails, tails, tails, assets, shares);
        vm.prank(tails);
        wrings.withdraw(assets, tails, tails);
    }

    function testRedeemTokens(uint256 shares) public {
        uint256 wringsPreBalance = wrings.balanceOf(knuckles);
        uint256 ringsPreBalance = rings.balanceOf(knuckles);
        vm.assume(shares >= 1 && shares <= wringsPreBalance);
        uint256 assets = wrings.convertToAssets(shares);
        vm.prank(knuckles);
        wrings.redeem(shares, knuckles, knuckles);
        uint256 wringsPostBalance = wrings.balanceOf(knuckles);
        uint256 ringsPostBalance = rings.balanceOf(knuckles);
        bool success = wringsPostBalance == wringsPreBalance - shares && ringsPostBalance == ringsPreBalance + assets;
        assertEq(success, true);
    }

    function testRedeemEmit(uint256 shares) public {
        vm.assume(shares >= 1 && shares <= wrings.balanceOf(eggman));
        uint256 assets = wrings.convertToAssets(shares);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(eggman, eggman, eggman, assets, shares);
        vm.prank(eggman);
        wrings.redeem(shares, eggman, eggman);
    }

    function testRedeemThreeParty(uint256 shares) public {
        uint256 wringsPreBalance = wrings.balanceOf(eggman);
        uint256 ringsPreBalance = rings.balanceOf(tails);
        vm.assume(shares >= 1 && shares <= wringsPreBalance);
        uint256 assets = wrings.convertToAssets(shares);
        vm.prank(eggman);
        rings.approve(sonic, 2**256-1);
        vm.prank(sonic);
        wrings.redeem(shares, tails, eggman);
        uint256 wringsPostBalance = wrings.balanceOf(eggman);
        uint256 ringsPostBalance = rings.balanceOf(tails);
        bool success = wringsPostBalance == wringsPreBalance - shares && ringsPostBalance == ringsPreBalance + assets;
        assertEq(success, true);
    }
    
    function testRedeemThreePartyEmit(uint256 shares) public {
        vm.assume(shares >= 1 && shares <= wrings.balanceOf(eggman));
        uint256 assets = wrings.convertToAssets(shares);
        vm.expectEmit(true, true, true, true);
        emit Withdraw(sonic, tails, eggman, assets, shares);
         vm.prank(eggman);
        rings.approve(sonic, 2**256-1);
        vm.prank(sonic);
        wrings.redeem(shares, tails, eggman);
    }
}