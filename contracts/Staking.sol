// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Store.sol";

contract TokenStaking is Ownable, Store {
    using Math for uint256;

    constructor(
        address _tokenAddress,
        uint256 _lockinTime
    ) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
        LOCKIN_TIME = _lockinTime;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "insufficient Allowance"
        );
        token.transferFrom(msg.sender, address(this), _amount);
        stakedAmounts[msg.sender].push(
            Stake({
                amount: _amount,
                addTime: block.timestamp,
                lastUpdateTime: block.timestamp
            })
        );

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _index) external {
        uint256 amount = stakedAmounts[msg.sender][_index].amount;
        uint256 addedTime = stakedAmounts[msg.sender][_index].addTime;
        require(amount > 0, "Insufficient amout to withdraw");
        require(
            addedTime + LOCKIN_TIME <= block.timestamp,
            "Lock in period not compleated"
        );
        require(amount > 0, "No tokens staked");
        uint256 reward = calculateReward(msg.sender, _index);
        (, uint256 totalAmount) = amount.tryAdd(reward);
        delete stakedAmounts[msg.sender][_index];
        token.transfer(msg.sender, totalAmount);
        emit Unstaked(msg.sender, amount, reward);
    }

    function calculateReward(
        address _user,
        uint256 _index
    ) public view returns (uint256) {
        uint256 amount = stakedAmounts[_user][_index].amount;
        uint256 profitUsdt = usdtToken.balanceOf(address(this));
        (, uint256 reward) = profitUsdt.tryDiv(amount);
        return reward;
    }

    function setLockInTime(uint256 _newLockInTime) external onlyOwner {
        require(_newLockInTime >= 0, "Lock in time cannot be negative");
        LOCKIN_TIME = _newLockInTime;
    }
}
