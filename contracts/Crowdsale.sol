// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Affiliate.sol";

contract Crowdesale is Ownable, AffiliateProgram {
    using SafeCast for int256;
    using SafeMath for uint256;

    uint8 constant REFERRAL_RATE = 20;
    address public wallet;
    bool private locked;
    uint256 MAIN_SITE_PRICE;
    uint256 AFFILIATE_PRICE;

    AggregatorV3Interface internal dataFeed;

    constructor(
        address _walletAddress,
        ERC20 _token,
        ERC20 _tokenUSDT,
        address _aggregatorAddress,
        address _transferAccount,
        uint256 mainSitePrice,
        uint256 affiliatePrice
    )
        AffiliateProgram(
            REFERRAL_RATE,
            IERC20(_token),
            IERC20(_tokenUSDT),
            _transferAccount
        )
    {
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
            "CrowdeSale: main site price cannot be less then 0"
        );
        require(
            affiliatePrice > 0,
            "CrowdeSale: affiliate price cannot be less then 0"
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
        (
            ,
            /* uint80 roundID */ int answer /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = dataFeed.latestRoundData();
        uint256 decimals = dataFeed.decimals();
        uint256 ethPrice = answer.toUint256().div(10 ** decimals);
        uint256 usdtAmount = value.mul(ethPrice).div(10 ** 18);
        uint256 tokenAmount = usdtAmount.mul(10 ** 18).div(MAIN_SITE_PRICE);
        payable(wallet).transfer(value);
        require(
            token.transfer(msg.sender, tokenAmount),
            "Token transfer failed"
        );
        emit TokensPurchased(msg.sender, value, tokenAmount);
    }

    function buyTokensWithBNB(
        address _affiliateAddress
    ) external payable nonReentrant sufficientFund {
        uint256 value = msg.value;
        require(value > 0, "CrowdeSale: ETH value can't be 0");
        (
            ,
            /* uint80 roundID */ int answer /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = dataFeed.latestRoundData();
        uint256 decimals = dataFeed.decimals();
        uint256 ethPrice = answer.toUint256().div(10 ** decimals);
        uint256 usdtAmount = value.mul(ethPrice).div(10 ** 18);
        uint256 tokenAmount;
        if (_affiliateAddress != address(0)) {
            tokenAmount = usdtAmount.mul(10 ** 18).div(AFFILIATE_PRICE);
            if (affiliates[_affiliateAddress] > 0) {
                addCommission(_affiliateAddress, usdtAmount, msg.sender);
            }
        } else {
            tokenAmount = usdtAmount.mul(10 ** 18).div(MAIN_SITE_PRICE);
        }
        payable(wallet).transfer(value);
        require(
            token.transfer(msg.sender, tokenAmount),
            "Token transfer failed"
        );
        emit TokensPurchased(msg.sender, value, tokenAmount);
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
            "insufficient Allowance"
        );
        uint256 tokenAmount;
        if (_affiliateAddress != address(0)) {
            tokenAmount = _usdtAmount.mul(10 ** 18).div(AFFILIATE_PRICE);
            if (affiliates[_affiliateAddress] > 0) {
                addCommission(_affiliateAddress, _usdtAmount, msg.sender);
            }
        } else {
            tokenAmount = _usdtAmount.mul(10 ** 18).div(MAIN_SITE_PRICE);
        }
        require(
            tokenUSDT.transferFrom(msg.sender, wallet, _usdtAmount),
            "USDT transfer failed"
        );
        require(
            token.transfer(msg.sender, tokenAmount),
            "Token transfer failed"
        );
        emit TokensPurchased(msg.sender, _usdtAmount, tokenAmount);
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
            address(_newAggregatorAddress) != address(0),
            "Aggregator address must be not zero address"
        );
        dataFeed = AggregatorV3Interface(_newAggregatorAddress);
    }
}
