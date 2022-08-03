// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISimpleSwap {

    function init(uint256 xIn, uint256 yIn) external returns(uint256 zOut);
    
    function addLiquidity(uint256 xIn) external returns(uint256 zOut);

    function removeLiquidity(uint256 zIn) external returns(uint256 xOut, uint256 yOut);

    function swapXforY(uint256 xIn) external returns(uint256 yOUt);

    function swapYforX(uint256 yIn) external returns(uint256 yOut);

    function swapXforExactY(uint256 yOut) external returns(uint256 xIn);

    function swapYforExactX(uint256 xOut) external returns(uint256 yIn);
}