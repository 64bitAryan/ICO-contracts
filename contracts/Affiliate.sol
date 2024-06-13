// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AffiliateProgram is Ownable {
    uint8 public commissionRate;
    IERC20 public token;
    IERC20 public tokenUSDT;
    address public transferAccount;

    constructor(
        uint8 _rate,
        IERC20 _token,
        IERC20 _tokenUSDT,
        address _transferAccount
    ) Ownable(msg.sender) {
        commissionRate = _rate;
        token = _token;
        tokenUSDT = _tokenUSDT;
        transferAccount = _transferAccount;
    }

    mapping(address => uint8) public affiliates;
    mapping(address => uint256) public accumulatedCommission;

    function getAffiliates(
        address _affiliateAddress
    ) public view returns (uint8) {
        return affiliates[_affiliateAddress];
    }

    function getAccumulatedCommission(
        address _address
    ) public view returns (uint256) {
        return accumulatedCommission[_address];
    }

    event AffiliateRegistered(address indexed affiliateWallet);

    event AccumulatedCommission(
        address indexed customer,
        uint256 value,
        address indexed affiliate,
        uint256 commission
    );

    event WithdrawCommission(address indexed customer, uint256 value);

    event ChangeCommisionRate(uint8 newRate);

    event ChangeTokenAddress(address newTokenAddress);

    modifier onlyTransferAccount() {
        require(
            transferAccount == msg.sender,
            "Unauthorized Transfer Account!"
        );
        _;
    }

    function registerAsAffiliate(address _affiliateAddress) external {
        affiliates[_affiliateAddress] = commissionRate;
        emit AffiliateRegistered(_affiliateAddress);
    }

    function addCommission(
        address _affiliate,
        uint256 _boughtValue,
        address _buyer
    ) internal {
        require(_boughtValue > 0, "Purchase value must be greater than 0");
        require(affiliates[_affiliate] > 0, "Invalid affiliate");
        require(
            _affiliate != _buyer,
            "Affiliate cannot be the same as customer"
        );

        uint256 commission = (_boughtValue * affiliates[_affiliate]) / 100;
        accumulatedCommission[_affiliate] += commission;
        emit AccumulatedCommission(
            _buyer,
            _boughtValue,
            _affiliate,
            commission
        );
    }

    function addCommissionByOwner(
        address _affiliate,
        uint256 _boughtValue,
        uint256 _transferAmount,
        address _buyer
    ) public onlyTransferAccount {
        require(_boughtValue > 0, "Purchase value must be greater than 0");
        require(
            _affiliate != _buyer,
            "Affiliate cannot be the same as customer"
        );

        if (affiliates[_affiliate] == 0) {
            affiliates[_affiliate] = commissionRate;
        }

        uint256 commission = (_boughtValue * affiliates[_affiliate]) / 100;
        accumulatedCommission[_affiliate] += commission;
        token.transfer(_buyer, _transferAmount);
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
            tokenUSDT.balanceOf(address(this)) > commission,
            "Insufficnet contract balance"
        );
        accumulatedCommission[msg.sender] = 0;
        tokenUSDT.transfer(msg.sender, commission);
        emit WithdrawCommission(msg.sender, commission);
    }

    function changeCommissionRate(uint8 _newRate) external onlyOwner {
        commissionRate = _newRate;
        emit ChangeCommisionRate(commissionRate);
    }

    function changeTokenAddress(IERC20 _newToken) external onlyOwner {
        token = _newToken;
        emit ChangeTokenAddress(address(_newToken));
    }

    function changeUSDTTokenAddress(IERC20 _newUSDTToken) external onlyOwner {
        tokenUSDT = _newUSDTToken;
        emit ChangeTokenAddress(address(_newUSDTToken));
    }

    function changeTransferAccount(
        address _newTransferAccount
    ) external onlyOwner {
        transferAccount = _newTransferAccount;
    }
}
