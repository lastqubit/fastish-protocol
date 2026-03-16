// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

contract TestRejectEther {
    receive() external payable {
        revert("NO_ETH");
    }
}
