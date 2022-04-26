pragma solidity ^0.8.13;

import "./AbandonAbstract.t.sol";
import "forge-std/Test.sol";

contract AbandonTest is AbandonAbstract {


    function testNameCanBeRegisteredAfterRelease() public {
        vm.prank(bubsy);
        r.registerName("Bubsy");
        assertEq(r.nameToUser("Bubsy"), bubsy);
    }
}