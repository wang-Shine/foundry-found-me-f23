// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 5 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;
    address public immutable owner;
    AggregatorV3Interface private priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MIN_USD, "didn't send enough ETH");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            s_addressToAmountFunded[s_funders[funderIndex]] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "send faild");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call faild");
    }

    function getVersion() internal view returns(uint256) {
        return priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "must be owner!");
        if(msg.sender != owner) revert NotOwner();
        _;
    }

    receive() external payable { 
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAmountFunded(address funder) external view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }
}