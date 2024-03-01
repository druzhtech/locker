// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

interface ILocker {
    function createOrderWithAmount(
        address[] memory users,
        uint256 amount
    ) external payable returns (bytes32 orderId);

    function claim(bytes32 orderId) external returns (bool result);
}