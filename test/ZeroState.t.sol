// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/MechaSwap.sol";
import "yield-utils-v2/token/IERC20.sol";

contract ZeroState is Test {

    MechaSwap public swap;

    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IERC20 iWETH = IERC20(WETH);
    IERC20 iDAI = IERC20(DAI);

    address char = address(0x1);
    address amuro = address(0x2);
    address gharma = address(0x3);

    address[] users = [char, amuro, gharma];

    event Init(address indexed user, uint256 amountX, uint256 amountY, uint256 amountZ);
    event LiquidityProvided(address indexed user, uint256 amountX, uint256 amountY, uint256 amountZ);
    event LiquidityRemoved(address indexed user, uint256 amountX, uint256 amountY, uint256 amountZ);
    event Swap(address indexed user, uint256 xIn, uint256 yIn, uint256 xOut, uint256 yOut);
    
    function setUp() public virtual {

        for(uint i = 0; i < users.length; ++i) {
            deal(DAI, users[i], 1e30);
            deal(WETH, users[i], 1e24);
            
        }

        vm.prank(char);
        swap = new MechaSwap(iDAI, iWETH);
    }
}
