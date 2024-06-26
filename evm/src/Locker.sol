// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import "./ILocker.sol";

contract Locker is ILocker {
    address public owner;
    uint256 public feePrice;
    uint256 public feeAmount;

    // cutomers => orderId
    mapping(address => bytes32[]) public customers;

    // orderId => (user => amount)
    mapping(bytes32 => mapping(address => uint256)) public orders;

    event OrderCreated(
        bytes32 indexed orderId,
        address indexed customer,
        address[] users,
        uint256 amount
    );

    error NotEnoughValue(uint256 excepted, uint256 actual);

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not owner");
        _;
    }

    constructor(uint256 _fee) {
        owner = msg.sender;
        feePrice = _fee;
    }

    function createOrderWithAmount(
        address[] memory users,
        uint256 amount
    ) external payable override returns (bytes32 orderId) {
        uint256 allAmount = users.length * amount;
        require(msg.value >= allAmount + feePrice, "not Enough fee");

        feeAmount += msg.value - allAmount;

        if (msg.value >= allAmount) {
            orderId = keccak256(abi.encodePacked(msg.sender, users, amount));
            for (uint8 count = 0; count < users.length; count++) {
                orders[orderId][users[count]] = amount;
            }

            customers[msg.sender].push(orderId);

            emit OrderCreated(orderId, msg.sender, users, amount);
        } else {
            revert NotEnoughValue(allAmount, msg.value);
        }
    }

    function createOrderWithoutAmount(
        address[] memory users
    ) public payable returns (bytes32 orderId) {
        uint256 amount = msg.value / users.length;

        orderId = keccak256(abi.encodePacked(msg.sender, users, amount));

        for (uint8 count = 0; count < users.length; count++) {
            orders[orderId][users[count]] = amount;
        }

        customers[msg.sender].push(orderId);

        emit OrderCreated(orderId, msg.sender, users, amount);
    }

    function claim(bytes32 orderId) external override returns (bool result) {
        require(orders[orderId][msg.sender] != 0, "already claimed");

        orders[orderId][msg.sender] = 0;

        payable(msg.sender).transfer(orders[orderId][msg.sender]);

        return true;
    }

    function changeFeePrice(uint256 newFeePrice) public onlyOwner {
        feePrice = newFeePrice;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(feeAmount);
    }
}
