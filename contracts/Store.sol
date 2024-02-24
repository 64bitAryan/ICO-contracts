// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Store {
    using Math for uint256;

    IERC20 public token;
    IERC20 public usdtToken;
    uint256 public REWARD_RATE;
    uint256 public LOCKIN_TIME;

    struct Stake {
        uint256 amount;
        uint256 addTime;
        uint256 lastUpdateTime;
    }

    mapping(address => Stake[]) public stakedAmounts;

    event ClaimDivident(address indexed user, uint256 amount, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
}
