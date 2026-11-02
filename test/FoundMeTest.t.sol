// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { FundMe, NotOwner } from "../src/FoundMe.sol";
import { DeployFundMe } from "../script/DeployFundMe.s.sol";

contract FoundMeTest is Test {
    FundMe fundMe;
    address user = makeAddr("user");

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user, 100e18);
    }

    function testMinUsd() public view {
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    function testOwner() public view {
        assertEq(fundMe.owner(), msg.sender);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        // 发送非常少的金额，远低于 $5 的最低要求
        // 假设 ETH = $2000，需要至少 0.0025 ETH (5/2000)
        // 发送 0.001 ETH 应该会失败
        fundMe.fund{value: 0.001 ether}();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(user);
        fundMe.fund{value: 10e18}();
        uint256 amountFunded = fundMe.getAmountFunded(user);
        assertEq(amountFunded, 10e18);
    }
    
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(user);
        fundMe.fund{value: 10e18}();
        assertEq(fundMe.getFunder(0), user);
    }

    modifier funded() {
        vm.prank(user);
        fundMe.fund{value: 10e18}();
        _;
    }
    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(user);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.owner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.owner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.owner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
}