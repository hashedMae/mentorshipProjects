pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Registry.sol";

abstract contract ZeroState is Test{

    
        Registry public r;

        address sonic = address(0x1);
        address mario = address(0x2);
        address bubsy = address(0x3);

       function setUp() public virtual {
            r = new Registry();
        }
    }

