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
        uint256 lastUpdateTime;
    }

    fallback() external payable {}

    receive() external payable {}

    mapping(address => Stake[]) public stakedAmounts;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event ClaimDivident(address indexed user, uint256 amount, uint256 reward);

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
        stakedAmounts[msg.sender].push(
            Stake(_amount, block.timestamp, block.timestamp)
        );
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _index) external {
        Stake memory userStake = stakedAmounts[msg.sender][_index];
        require(userStake.amount > 0, "No stake available");
        if (userStake.lastUpdateTime + LOCKIN_TIME <= block.timestamp) {
            claimDivident(_index);
        }
        delete stakedAmounts[msg.sender][_index];
        stakeToken.transfer(msg.sender, userStake.amount);
        emit Unstaked(msg.sender, userStake.amount, 0);
    }

    function claimDivident(uint256 _index) public {
        Stake memory userStake = stakedAmounts[msg.sender][_index];
        require(userStake.amount > 0, "No stake available");
        require(
            userStake.lastUpdateTime + LOCKIN_TIME <= block.timestamp,
            "Lock time is not over"
        );
        uint256 dividentReward = _calculateReward();
        require(
            usdtToken.balanceOf(address(this)) >= dividentReward,
            "Not enough balance to provide divident"
        );
        usdtToken.transfer(msg.sender, dividentReward);
        stakedAmounts[msg.sender][_index].lastUpdateTime = block.timestamp;
        emit ClaimDivident(msg.sender, userStake.amount, dividentReward);
    }

    function calculateReward(
        uint256 _index,
        address _user
    ) public view returns (uint256) {
        Stake memory userStake = stakedAmounts[_user][_index];
        require(
            userStake.lastUpdateTime + LOCKIN_TIME <= block.timestamp,
            "Lock time is not over"
        );
        uint256 dividentReward = _calculateReward();
        return dividentReward;
    }

    function _calculateReward() internal view returns (uint256) {
        uint256 etherPresent = address(this).balance;
        uint256 usdtPresent = usdtToken.balanceOf(address(this));
        uint256 tokenTotalSupply = stakeToken.totalSupply();
        uint256 divident = (usdtPresent + etherPresent) / tokenTotalSupply;
        require(divident > 0, "Divident is 0");
        return divident;
    }

    function withdrawUsdt(address _to) external onlyOwner {
        require(
            usdtToken.balanceOf(address(this)) > 0,
            "No Tokenavailable to withdraw"
        );
        usdtToken.transfer(_to, usdtToken.balanceOf(address(this)));
    }

    function withdrawEther(address _to) external onlyOwner {
        require(address(this).balance > 0, "No Ether available to withdraw");
        (bool success, ) = _to.call{value: address(this).balance}("");
        if (!success) {
            revert("Transfer failed");
        }
    }
}
