// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Rings.sol";
import "src/WRings.sol";
import "yield-utils-v2/math/WMul.sol";
import "yield-utils-v2/math/WDiv.sol";
import "yield-utils-v2/token/IERC20.sol";
import "src/Borrower.sol";
import "src/interfaces/IERC3156FlashLender.sol";

abstract contract ZeroState is Test {
    
    Rings public rings;
    WRings public wrings;
    Borrower public borrower;


    address sonic = address(0x1);
    address tails = address(0x2);
    address knuckles = address(0x3);
    address eggman = address(0x4);
    address rouge = address(0x5);
    address bigTheCat = address(0x6);

    address[] users = [sonic, tails, knuckles, eggman];

    event Deposit(address indexed caller, address indexed owner, uint256 assetss, uint256 shares);
    
    function setUp() public virtual {
        rings = new Rings();
        wrings = new WRings(rings);
        borrower = new Borrower(IERC3156FlashLender(wrings));

        for(uint i = 0; i < users.length; i++) {
            rings.mint(users[i], 1e26);
        }

        rings.mint(rouge, 1e26);
        rings.mint(address(borrower), 1e26);

        vm.startPrank(rouge);
        rings.approve(address(wrings), 2**256-1);
        wrings.init(1e26, rouge);
        vm.stopPrank();
    }

    function _convertToShares(uint256 _assets) internal view returns(uint256 shares) {
        uint256 _reserves = rings.balanceOf(address(wrings));
        shares = WMul.wmul(WDiv.wdiv(_assets, _reserves), wrings.totalSupply());
    }

    function _convertToAssets(uint256 _shares) internal view returns(uint256 assets) {
       uint256 _reserves = rings.balanceOf(address(wrings));
       uint256 _portion = WDiv.wdiv(_shares, wrings.totalSupply());
       assets = WMul.wmul(_portion, _reserves);
    }

    
}
