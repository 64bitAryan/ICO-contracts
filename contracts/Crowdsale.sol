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

    ERC20 public tokenUSDT;
    address public wallet;
    uint256 public disperseAmount;
    uint256 public REFERRAL_RATE;
    bool private locked;

    AggregatorV3Interface internal dataFeed;

    constructor(
        address _walletAddress,
        ERC20 _token,
        ERC20 _tokenUSDT,
        uint256 _amount,
        address _aggregatorAddress,
        uint256 _referralRate,
        uint8 _affiliateRate
    ) AffiliateProgram(_affiliateRate, IERC20(_token)) {
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
        require(_amount > 0, "CrowdeSale: disperse amount can't be zero");

        wallet = _walletAddress;
        disperseAmount = _amount;
        token = _token;
        tokenUSDT = _tokenUSDT;
        REFERRAL_RATE = _referralRate;

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

    modifier sufficientUSDTFund() {
        uint256 currentTokenAmount = tokenUSDT.balanceOf(address(this));
        require(
            currentTokenAmount > 0,
            "CrowdeSale: Insufficient tokenUSDT amount"
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
        // payable(wallet).transfer(value);
        value = value.mul(REFERRAL_RATE).div(100);
        require(
            token.transfer(msg.sender, value.mul(ethPrice)),
            "Token transfer failed"
        );
        emit TokensPurchased(msg.sender, value, value.mul(ethPrice));
    }

    function buyTokens(
        uint256 _usdtAmount,
        address _affiliateAddress
    ) external {
        require(_usdtAmount > 0, "Amount must be greater than zero");
        require(
            tokenUSDT.balanceOf(msg.sender) >= _usdtAmount,
            "Insufficient balance"
        );
        require(
            tokenUSDT.allowance(msg.sender, address(this)) >= _usdtAmount,
            "insufficient Allowance"
        );
        require(
            tokenUSDT.transferFrom(msg.sender, address(this), _usdtAmount),
            "USDT transfer failed"
        );
        require(
            token.transfer(msg.sender, _usdtAmount),
            "Token transfer failed"
        );
        if (_affiliateAddress != address(0)) {
            addCommission(_affiliateAddress, _usdtAmount, msg.sender);
        }
        emit TokensPurchased(msg.sender, _usdtAmount, _usdtAmount);
    }

    function withdrawFunds() external onlyOwner {
        payable(wallet).transfer(address(this).balance);
    }

    function withdrawTokens() external onlyOwner sufficientFund {
        require(
            token.transfer(wallet, token.balanceOf(address(this))),
            "Token withdraw failed"
        );
    }

    function withdrawUSDT() external onlyOwner sufficientUSDTFund {
        require(
            tokenUSDT.transfer(wallet, tokenUSDT.balanceOf(address(this))),
            "USDT withdraw failed"
        );
    }

    function setReferralRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Referral rate must be greater than zero");
        REFERRAL_RATE = _newRate;
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
