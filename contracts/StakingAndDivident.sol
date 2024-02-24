// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Staking.sol";

contract StakingAndDivident is Ownable, TokenStaking {
    constructor(
        IERC20 _usdtToken,
        address _tokenAddress,
        uint256 _StakingRewardRate,
        uint256 _lockinTime
    ) TokenStaking(_tokenAddress, _StakingRewardRate, _lockinTime) {
        usdtToken = _usdtToken;
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

    function calculateDividentReward(
        address _user,
        uint256 _index
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
        uint256 tokenTotalSupply = token.totalSupply();
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
