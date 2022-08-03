// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface ICollateralizedVault {

    function daiPrice() external view returns(uint256 answer);

    function usdcPrice() external view returns(uint256 answer);

    function availableDai(address user) external view returns(uint256 answer);

    function availableUSDC(address user) external view returns(uint256 answer);

    function totalDebt(address user) external view returns(uint256 answer);

    function tokenDebts(address user) external view returns(uint256 daiDebt, uint256 usdcDebt);

    function deposit(uint256 amount) external;

    function borrowDai(uint256 amount) external;

    function borrowUSDC(uint256 amount) external;

    function repayDai(uint256 amount) external;

    function repayUSDC(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function ration(address user) external view returns(uint256 userRatio);

    function liquidate(address user) external returns(uint256 lqdtdWETH);
    
}