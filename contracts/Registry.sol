//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface Registry {
    function getBestPoolsWithLimit(
        address fromToken,
        address destToken,
        uint256 limit
    ) external view returns (address[] memory pools);
}
