// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CrowdsaleEth is Ownable {
    using SafeCast for int256;
    using SafeMath for uint256;

    uint8 constant REFERRAL_RATE = 20;
    address public wallet;
    bool private locked;
    uint256 MAIN_SITE_PRICE;
    uint256 AFFILIATE_PRICE;

    ERC20 public token;
    ERC20 public tokenUSDT;
    AggregatorV3Interface internal dataFeed;

    constructor(
        address _walletAddress,
        ERC20 _token,
        ERC20 _tokenUSDT,
        address _aggregatorAddress,
        uint256 mainSitePrice,
        uint256 affiliatePrice
    ) Ownable(msg.sender) {
        require(
            _walletAddress != address(0),
            "CrowdeSale: wallet address can't be zero"
        );
        require(
            address(_token) != address(0),
            "CrowdeSale: token address can't be zero"
        );
        require(
            address(_tokenUSDT) != address(0),
            "CrowdeSale: USDT token address can't be zero"
        );
        require(
            mainSitePrice > 0,
            "CrowdeSale: main site price cannot be less than 0"
        );
        require(
            affiliatePrice > 0,
            "CrowdeSale: affiliate price cannot be less than 0"
        );

        MAIN_SITE_PRICE = mainSitePrice;
        AFFILIATE_PRICE = affiliatePrice;
        wallet = _walletAddress;
        token = _token;
        tokenUSDT = _tokenUSDT;

        dataFeed = AggregatorV3Interface(_aggregatorAddress);
    }

    event TokensPurchased(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );

    event TransferUsdt(
        address useAddress,
        address affiliateAddress,
        uint256 tokenAmount,
        uint256 usdtAmount
    );

    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier sufficientFund() {
        uint256 currentTokenAmount = token.balanceOf(address(this));
        require(
            currentTokenAmount > 0,
            "CrowdeSale: Insufficient token amount"
        );
        _;
    }

    receive() external payable nonReentrant sufficientFund {
        uint256 value = msg.value;
        require(value > 0, "CrowdeSale: ETH value can't be 0");
        (, int answer, , , ) = dataFeed.latestRoundData();
        uint256 decimals = dataFeed.decimals();
        uint256 ethPrice = answer.toUint256().div(10 ** decimals);
        uint256 usdtAmount = value.mul(ethPrice).div(10 ** 18);
        uint256 tokenAmount = usdtAmount.mul(10 ** 18).div(MAIN_SITE_PRICE);
        payable(wallet).transfer(value);
        emit TransferUsdt(msg.sender, address(0), tokenAmount, usdtAmount);
    }

    function buyTokensWithEth(
        address _affiliateAddress
    ) external payable nonReentrant sufficientFund {
        uint256 value = msg.value;
        require(value > 0, "CrowdeSale: ETH value can't be 0");
        (, int answer, , , ) = dataFeed.latestRoundData();
        uint256 decimals = dataFeed.decimals();
        uint256 ethPrice = answer.toUint256().div(10 ** decimals);
        uint256 usdtAmount = value.mul(ethPrice).div(10 ** 18);
        uint256 tokenAmount;
        if (_affiliateAddress != address(0)) {
            tokenAmount = usdtAmount.mul(10 ** 18).div(AFFILIATE_PRICE);
            // Implement affiliate logic here if needed
        } else {
            tokenAmount = usdtAmount.mul(10 ** 18).div(MAIN_SITE_PRICE);
        }
        payable(wallet).transfer(value);
        emit TransferUsdt(
            msg.sender,
            _affiliateAddress,
            tokenAmount,
            usdtAmount
        );
    }

    function buyTokens(
        uint256 _usdtAmount,
        address _affiliateAddress
    ) external sufficientFund {
        require(_usdtAmount > 0, "Amount must be greater than zero");
        require(
            tokenUSDT.balanceOf(msg.sender) >= _usdtAmount,
            "Insufficient balance"
        );
        require(
            tokenUSDT.allowance(msg.sender, address(this)) >= _usdtAmount,
            "Insufficient Allowance"
        );
        uint256 tokenAmount;
        if (_affiliateAddress != address(0)) {
            tokenAmount = _usdtAmount.mul(10 ** 18).div(AFFILIATE_PRICE);
            // Implement affiliate logic here if needed
        } else {
            tokenAmount = _usdtAmount.mul(10 ** 18).div(MAIN_SITE_PRICE);
        }
        require(
            tokenUSDT.transferFrom(msg.sender, wallet, _usdtAmount),
            "USDT transfer failed"
        );
        emit TransferUsdt(
            msg.sender,
            _affiliateAddress,
            tokenAmount,
            _usdtAmount
        );
    }

    function withdrawTokens() external onlyOwner sufficientFund {
        require(
            token.transfer(wallet, token.balanceOf(address(this))),
            "Token withdraw failed"
        );
    }

    function setAggregatorAddress(
        address _newAggregatorAddress
    ) external onlyOwner {
        require(
            _newAggregatorAddress != address(0),
            "Aggregator address must be not zero address"
        );
        dataFeed = AggregatorV3Interface(_newAggregatorAddress);
    }
}
