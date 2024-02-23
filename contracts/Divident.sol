// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DividentProgram is Ownable {
    IERC20 public stakeToken;
    IERC20 public usdtToken;
    uint256 public LOCKIN_TIME;

    constructor(
        IERC20 _stakeToken,
        IERC20 _usdtToken,
        uint256 _lockinTime
    ) Ownable(msg.sender) {
        stakeToken = _stakeToken;
        LOCKIN_TIME = _lockinTime;
        usdtToken = _usdtToken;
    }

    struct Stake {
        uint256 amount;
        uint256 addTime;
    }

    mapping(address => Stake[]) public stakedAmounts;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);

    function stake(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            stakeToken.balanceOf(msg.sender) >= _amount,
            "Not enough balance"
        );
        require(
            stakeToken.allowance(msg.sender, address(this)) >= _amount,
            "Not enough allowance"
        );
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        stakedAmounts[msg.sender].push(Stake(_amount, block.timestamp));
        emit Staked(msg.sender, _amount);
    }

    function calculateReward(
        uint256 _index,
        address _user
    ) public view returns (uint256) {
        Stake memory userStake = stakedAmounts[_user][_index];
        require(
            userStake.addTime + LOCKIN_TIME <= block.timestamp,
            "Lock time is not over"
        );
        uint256 etherPresent = address(this).balance;
        uint256 usdtPresent = usdtToken.balanceOf(address(this));
        uint256 tokenTotalSupply = stakeToken.totalSupply();
        uint256 divident = (usdtPresent + etherPresent) / tokenTotalSupply;
        require(divident > 0, "Divident is 0");
        return divident;
    }
}
