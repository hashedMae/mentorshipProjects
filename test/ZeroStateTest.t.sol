// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    event Deposit(address indexed caller, address indexed owner, uint256 assetss, uint256 shares);

    function testDepositTokens(uint256 assets) public {
        uint256 ringsPreBalance = rings.balanceOf(tails);
        uint256 wringsPreBalance = wrings.balanceOf(tails);
        vm.assume(assets > 1*10**18 && assets < ringsPreBalance);
        vm.startPrank(tails);
        rings.approve(address(wrings), (2**256-1));
        wrings.deposit(assets, tails);
        vm.stopPrank();
        uint256 ringsPostBalance = rings.balanceOf(tails);
        uint256 wringsPostBalance = wrings.balanceOf(tails);
        bool success = ringsPostBalance == (ringsPreBalance - assets) && wringsPostBalance == (wringsPreBalance + (WMul.wmul(assets*10**9, exchange)/10**9));
        assertEq(success, true);
        
    }

    function testDepositEventEmit(uint256 assets) public {
        vm.assume(assets < 100000000*10**18);
        uint256 shares = wrings.convertToShares(assets);
        vm.startPrank(knuckles);
        rings.approve(address(wrings), (2**256-1));
        vm.expectEmit(true, true, false, true);
        emit Deposit(knuckles, knuckles, assets, shares);
        wrings.deposit(assets, knuckles);
        vm.stopPrank;
    }

    

    function testMintTokens(uint256 shares) public {
        uint256 ringsPreBalance = rings.balanceOf(sonic);
        uint256 wringsPreBalance = wrings.balanceOf(sonic);
        uint256 maxShares = wrings.convertToShares(ringsPreBalance);
        vm.assume(shares > 0);
        vm.assume(shares < maxShares);
        vm.startPrank(sonic);
        rings.approve(address(wrings), (2**256-1));
        wrings.mint(shares, sonic);
        vm.stopPrank();
        uint256 ringsPostBalance = rings.balanceOf(sonic);
        uint256 wringsPostBalance = wrings.balanceOf(sonic);
        bool success = ringsPostBalance == (ringsPreBalance - WDiv.wdiv(shares*10**9, exchange)/10**9) && wringsPostBalance == (wringsPreBalance + shares);
        assertEq(success, true);
    }

    function testMintEmit(uint256 shares) public {
        uint256 ringsPreBalance = rings.balanceOf(sonic);
        uint256 maxShares = wrings.convertToShares(ringsPreBalance);
        vm.assume(shares > 0);
        vm.assume(shares < maxShares);
        uint256 assets = WDiv.wdiv(shares*10**9, exchange)/10**9;
        vm.expectEmit(true, true, false, true);
        emit Deposit(eggman, eggman, assets, shares);
        vm.startPrank(eggman);
        rings.approve(address(wrings), 2**256-1);
        wrings.mint(shares, eggman);
        vm.stopPrank();
    }
}