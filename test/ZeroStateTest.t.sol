// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    

    function testDepositTokens(uint256 assets) public {
        uint256 ringsPreBalance = rings.balanceOf(tails);
        uint256 wringsPreBalance = wrings.balanceOf(tails);
        assets = bound(assets, 1, ringsPreBalance);

        uint256 shares = _convertToShares(assets);


        vm.startPrank(tails);
        rings.approve(address(wrings), (2**256-1));
        wrings.deposit(assets, tails);
        vm.stopPrank();
        
        assertEq(rings.balanceOf(tails), ringsPreBalance - assets);
        assertEq(wrings.balanceOf(tails), wringsPreBalance + shares);
        
    }

    function testDepositEventEmit(uint256 assets) public {
        assets = bound(assets, 1, rings.balanceOf(knuckles));

        uint256 shares = _convertToShares(assets);


        vm.startPrank(knuckles);
        rings.approve(address(wrings), (2**256-1));
        vm.expectEmit(true, true, false, true);
        emit Deposit(knuckles, knuckles, assets, shares);
        wrings.deposit(assets, knuckles);
        vm.stopPrank;
    }

    

    function testMintTokens(uint256 shares) public {
        uint256 rBal = rings.balanceOf(sonic);
        uint256 wBal = wrings.balanceOf(sonic);
        uint256 maxShares = _convertToShares(rBal);
        shares = bound(shares, 1, maxShares);
        
        uint256 assets = _convertToAssets(shares);

        vm.startPrank(sonic);
        rings.approve(address(wrings), (2**256-1));
        wrings.mint(shares, sonic);
        vm.stopPrank();

        assertEq(wrings.balanceOf(sonic), wBal + shares);
        assertEq(rings.balanceOf(sonic), rBal - assets);
        
    }

    function testMintEmit(uint256 shares) public {
        uint256 rBal = rings.balanceOf(eggman);
        uint256 maxShares = _convertToShares(rBal);
        shares = bound(shares, 1, maxShares);
        
        uint256 assets = _convertToAssets(shares);

        vm.expectEmit(true, true, false, true);
        
        emit Deposit(eggman, eggman, assets, shares);
        
        vm.startPrank(eggman);
        rings.approve(address(wrings), 2**256-1);
        wrings.mint(shares, eggman);
        vm.stopPrank();
    }
}