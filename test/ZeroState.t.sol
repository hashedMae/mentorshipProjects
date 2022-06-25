// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/MultiCollateralVault.sol";
import "yield-utils/token/IERC20.sol";

    /// mainnet 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    /// rinkeby 0xab5400b26149A3fF5918EFCdeB2C37903042E9ee
    /// address USDC;

    /// mainnet 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    /// rinkeby 0xb4f6777e54788D261ec639bDedce6800cA07a744
    /// address WBTC;

    /// mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    /// rinkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
    /// address WETH
    
    /// mainnet 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4
    /// rinkeby 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
    /// @dev USDC/ETH Price Oracle
    /// AggregatorV3Interface uETHFeed;

    ///mainnet 0xdeb288F737066589598e9214E782fa5A8eD689e8
    ///rinkeby 0x2431452A0010a43878bF198e170F6319Af6d27F4
    ///@dev BTC/ETH Price Oracle
    /// AggregatorV3Interface bETHFeed;

contract ZeroState is Test {
 

    MultiCollateralVault public vault;

    address WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IERC20 iWETH = IERC20(WETH);
    IERC20 iWBTC = IERC20(WBTC);
    IERC20 iUSDC = IERC20(USDC);

    address rx78 = address(0x1);
    address zaku = address(0x2);
    address dom = address(0x3);
    address rickdom = address(0x4);
    address zeong = address(0x5);
    address gelgoog = address(0x6);

    address[] users = [rx78, zaku, dom, rickdom, zeong, gelgoog];

    AggregatorV3Interface oBTC = AggregatorV3Interface(0xdeb288F737066589598e9214E782fa5A8eD689e8);
    AggregatorV3Interface oUSDC = AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);

    bytes4 public constant LIQUIDATOR = bytes4(keccak256("_liquidate(address)"));
    bytes4 public constant COLLATERAL_ADMIN = bytes4(keccak256("_addCollateral(address, address)"));
    bytes4 public constant RATIO_ADMIN = bytes4(keccak256("_setRatio(address, uint256)"));
    
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    function setUp() public virtual {

        for(uint256 i = 0; i < users.length; i++) {
            deal(WBTC, users[i], 1000e18);
            deal(USDC, users[i], 1000000e6);
        }

        
        
        vm.startPrank(rx78);
        vault = new MultiCollateralVault(WETH);
        vault.grantRole(LIQUIDATOR, rx78);
        vault.grantRole(COLLATERAL_ADMIN, zaku);
        vault.grantRole(RATIO_ADMIN, dom);
        vm.stopPrank();
        
        deal(WETH, address(vault), 1e30);
    }
}