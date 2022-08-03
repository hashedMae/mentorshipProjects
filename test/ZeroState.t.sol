// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/CollateralizedVault.sol";
import "src/EasyLiquidator.sol";
import "src/FlashVault.sol";
import "src/SimpleSwap.sol";
import "yield-utils-v2/token/IERC20.sol";
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "yield-utils-v2/math/WDiv.sol";
import "yield-utils-v2/math/WMul.sol";
import "src/interfaces/ICollateralizedVault.sol";
import "src/interfaces/ISimpleSwap.sol";
import "src/interfaces/IERC3156FlashLender.sol";


/// mainnet 0x773616E4d11A78F511299002da57A0a94577F1f4
    /// rinkeby 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D
    /// DAI/ETH Price Oracle
    
    /// mainnet 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4
    /// rinkeby 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
    /// USDC/ETH Price Oracle

contract ZeroState is Test {

    uint256 internal constant UINT256_MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    CollateralizedVault public vault;
    SimpleSwap public sDAI;
    SimpleSwap public sUSDC;
    FlashVault public lDAI;
    FlashVault public lUSDC;

    EasyLiquidator public liquid;

    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IERC20 iWETH = IERC20(WETH);
    IERC20 iDAI = IERC20(DAI);
    IERC20 iUSDC = IERC20(USDC);

    address jyn = address(0x1);
    address cass = address(0x2);
    address ks = address(0x3);
    address baze = address(0x4);
    address orson = address(0x5);
    address[] public users = [jyn, cass, ks, baze, orson];

     event Liquidation(address indexed liquidator, 
        address indexed liquidatee,
        uint256 debtDAI,
        uint256 profitWETH);

    function setUp() public virtual {
        
        deal(WETH, ks, 1000e18);
        deal(DAI, ks, 2e25);
        deal(USDC, ks, 2000000e6);
        deal(WETH, cass, 1000e18);
        deal(DAI, cass, 2e25);
        deal(USDC, cass, 2000000e6);
        deal(WETH, baze, 1000e18);
        deal(DAI, baze, 2e25);
        deal(USDC, baze, 2000000e6);
        deal(WETH, orson, 1000e18);
        deal(DAI, orson, 2e25);
        deal(USDC, orson, 2000000e6);

        
    vm.startPrank(ks);
    vault = new CollateralizedVault(DAI, WETH, USDC, AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4), AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4));
    sDAI = new SimpleSwap(iDAI, iWETH);
    sUSDC = new SimpleSwap(iUSDC, iWETH);
    lDAI = new FlashVault(iDAI);
    lUSDC = new FlashVault(iUSDC);

    liquid = new EasyLiquidator(IERC3156FlashLender(address(lDAI)), ISimpleSwap(address(sDAI)), ICollateralizedVault(address(vault)), iWETH, iDAI);
    iDAI.transfer(address(vault), 2e24);
    iUSDC.transfer(address(vault), 2e12);
    vm.stopPrank();

    vm.startPrank(cass);
    iDAI.approve(address(lDAI), UINT256_MAX);
    iUSDC.approve(address(lUSDC), UINT256_MAX);
    lDAI.init(2e24, cass);
    lUSDC.init(2e12, cass);
    vm.stopPrank();

    uint256 xIn = 164489e19;
    vm.startPrank(ks);
    iDAI.approve(address(sDAI), UINT256_MAX);
    iWETH.approve(address(sDAI), UINT256_MAX);
    sDAI.init(164489e19, 1e21);
    vm.stopPrank();

    vm.startPrank(baze);
    iUSDC.approve(address(sUSDC), UINT256_MAX);
    iWETH.approve(address(sUSDC), UINT256_MAX);
    sUSDC.init(164489e7, 1e21);
    vm.stopPrank();

    vm.startPrank(orson);
    iWETH.approve(address(vault), UINT256_MAX);
    vault.deposit(5e19);
    vm.stopPrank();

    }
}
