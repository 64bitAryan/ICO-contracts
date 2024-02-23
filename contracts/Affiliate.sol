// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AffiliateProgram is Ownable {
    uint8 commissionRate;
    IERC20 public token;

    constructor(uint8 _rate, IERC20 _token) Ownable(msg.sender) {
        commissionRate = _rate;
        token = _token;
    }

    address[] pendingAffiliates;
    mapping(address => uint8) public affiliates;
    mapping(address => address) public customerToAffiliate;
    mapping(address => uint256) public accumulatedCommission;

    event AffiliateRegistered(address indexed affiliateWallet);

    event ApproveAffiliate(address indexed affiliateWallet, uint256 commission);

    event AccumulatedCommission(
        address indexed customer,
        uint256 value,
        address indexed affiliate,
        uint256 commission
    );

    event WithdrawCommission(address indexed customer, uint256 value);

    function registerAsAffiliate(address _affiliateAddress) external {
        pendingAffiliates.push(_affiliateAddress);
        emit AffiliateRegistered(_affiliateAddress);
    }

    function approveAffiliates(address _affiliateAddress) external onlyOwner {
        require(
            affiliates[_affiliateAddress] == 0,
            "Affiliate already approved"
        );
        affiliates[_affiliateAddress] = commissionRate;
        emit ApproveAffiliate(_affiliateAddress, commissionRate);
    }

    function addCommission(
        address _affiliate,
        uint256 _boughtValue,
        address _buyer
    ) external onlyOwner {
        require(_boughtValue > 0, "Purchase value must be greater than 0");
        require(affiliates[_affiliate] > 0, "Invalid affiliate");
        require(
            _affiliate != _buyer,
            "Affiliate cannot be the same as customer"
        );
        if (customerToAffiliate[_buyer] != address(0))
            require(
                customerToAffiliate[_buyer] == _affiliate,
                "Customer already has affiliate"
            );
        else customerToAffiliate[_buyer] = _affiliate;

        uint256 commission = (_boughtValue * affiliates[_affiliate]) / 100;
        accumulatedCommission[_affiliate] += commission;
        emit AccumulatedCommission(
            _buyer,
            _boughtValue,
            _affiliate,
            commission
        );
    }

    function withdrawCommission() external {
        uint256 commission = accumulatedCommission[msg.sender];
        require(commission > 0, "No commission to withdraw");
        require(
            token.balanceOf(address(this)) > commission,
            "Insufficnet contract balance"
        );
        accumulatedCommission[msg.sender] = 0;
        token.transfer(msg.sender, commission);
        emit WithdrawCommission(msg.sender, commission);
    }

    function withdrawTokes() external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function getCustomerAffiliate(
        address _customer
    ) external view returns (address) {
        return customerToAffiliate[_customer];
    }
}
