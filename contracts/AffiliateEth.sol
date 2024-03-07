// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AffiliateProgramEth is Ownable {
    uint8 public commissionRate;

    constructor(uint8 _rate) Ownable(msg.sender) {
        commissionRate = _rate;
    }

    mapping(address => uint8) public affiliates;

    event AffiliateRegistered(address indexed affiliateWallet);

    event ChangeCommisionRate(uint8 newRate);

    function registerAsAffiliate(address _affiliateAddress) external {
        affiliates[_affiliateAddress] = commissionRate;
        emit AffiliateRegistered(_affiliateAddress);
    }

    function changeCommissionRate(uint8 _newRate) external onlyOwner {
        commissionRate = _newRate;
        emit ChangeCommisionRate(commissionRate);
    }
}
