// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/interfaces/IOracle.sol";

contract MockOracle is IOracle {
    uint256 private rlbtPrice;

    function setRLBTPrice(uint256 price) external {
        rlbtPrice = price;
    }

    function getRLBTPrice() external view override returns (uint256) {
        return rlbtPrice;
    }
}
