//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./libraries/OracleLib.sol";

/**
 * @title DSCEngine
 * @author Osoraku
 * The system is designed to be as minial as possible,
 * and have the tokens maintain a 1 token == $1 peg.
 *
 * This stablecoin has the properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algoritmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized" At no point,
 *  should the value of all collateral <= the $ backed value of all DSC.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for mining
 * and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.
 */

contract DSCEngine is ReentrancyGuard {
    /////////////////////
    // Errors          //
    /////////////////////
    error DSCEngine__NeedMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreakHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    /////////////////////
    // Type            //
    /////////////////////
    using OracleLib for AggregatorV3Interface;

    /////////////////////
    // State Variables //
    /////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10; //10%のボーナス
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    //tokenToPriceFeed ETH/USDとか
    mapping(address token => address priceFeed) private s_priceFeeds;
    //user => token => amount　User→あるトークンの担保の預入量
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    /////////////////////
    // Events          //
    /////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed redeemedFrom, address indexed redeemedTo, address token, uint256 amount);

    /////////////////////
    // Modifier        //
    /////////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    /////////////////////
    // Functions        //
    /////////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        //ペアの組み合わせを作る。ETH/USD, BTC/USD, etc.
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////////////////////////////
    // External Functions     //
    ////////////////////////////

    //ETHなどを預けて、DSCを発行する
    /*
     * @param tokenCollateralAddress 預けるトークンのアドレス
     * @param amountCollateral 預けるトークンの量
     * @param amountDscToMint 発行するDSCの量
     * @notice この関数は、担保の預入とmintを１つのtransactionで行う
     */
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    //ETHなどを預ける（誰がどのくらい預けたか）
    /* 
     * @notice follows CEI pattern
     * @param tokenCollateralAddress 預けるトークンのアドレス
     * @param amountCollateral 預けるトークンの量
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    //DSCを燃やして、ETHなどを引き出す
    /*
    *  @param tokenCollateralAddress 引き出す担保トークンのアドレス
    *  @param amountCollateral 引き出す担保トークンの量
    *  @param amountDscToBurn バーンするDSCの量
    *  @notice この関数は、DSCのバーンと担保の引き出しを１つのtransactionで行う
    */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)
        external
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        //redeemCollateralが既にHealthFactorのcheckを行っているので、ここでは行わない。
    }

    //担保にしていたETHなどを引き出す
    //担保引き出し後もHealth Factorは1以上である必要がある。
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
        //HealthFactorが1を下回った場合は、revertする
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    //DSCを発行する
    /*
     * @notice follows CEI pattern
     * @param amountDscToMint 発行するDSCの量
     * @notice トークンの預入量が足りない場合は、revertする
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        //mintの量が預入量を超えている場合は、revertする
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    //DSCを燃やす
    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    //清算する
    /*
    * 担保価格の価値が下がったら誰かのポジションを清算する
    * $100 ETH backing $50 DSC
    * $20 ETH backing $50 DSC <- DSC isn't worth $1 anymore
    * $75 backing $50 DSC
    * $Liquidator take $75 backing and burns off the $50 DSC
    * $25 ETH backing $0 DSC
    */
    /*
     * @param callateral userから清算するためのerc20の担保トークンアドレス
     * @param user 清算するユーザーのアドレス. _healthFactorがMIN_HEALTH_FACTORを下回っていること
     * @param debtToCover 清算するDSCの量。バーンしてuserのhealthFactorを1以上にする。
     * @notice userの一部の清算を行える。
     * @notice userのfundsから清算ボーナスを得られる。
     * @notice この関数は、おおよそ200%以上の担保があることでワークすることを想定している。
     * @notice 既知のバグとしては、もしプロトコルが100％しか担保されていない場合、誰も清算できなくなる。
     * 例えば、誰かが清算される前に担保の価格が急落した場合などです。
     */
    function liquidate(address callateral, address user, uint256 debtToCover)
        external
        moreThanZero(debtToCover)
        nonReentrant
    {
        //userのHealthFactorを確認する
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }
        // we want to burn their DSC "debt"
        // and take their collateral
        // Bad User: $140 ETH, $100 DSC
        // debtToCover = $100 DSC
        // $100 of DSC == ??? ETH?
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(callateral, debtToCover);
        // 10%のボーナスをつける
        // つまり、100 DSCに対して110ドルのWETHを清算人に与える。
        // プロトコルが債務超過に陥った場合に清算する機能を実装すべきである。
        // そして、余った金額を金庫に積み立てる
        // 0.05 * 0.1 = 0.005, gettting 0.055
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(user, msg.sender, callateral, totalCollateralToRedeem);
        //burn DSC
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    //清算価格を取得する?違うかも。後で確認。
    /**
     * HealthFactorは大雑把にいうと、預入量/借入量で計算される。
     * 預入量が多いほど、HealthFactorは高くなり、安全であると言える。
     * Health Factor = (Collateral Value in USD) / (Debt Value in USD)
     */
    function getHealthFactor() external {}

    ///////////////////////////////////////
    // Private & Internal View Functions //
    ///////////////////////////////////////

    /*
     * @dev Low-level internal function, do not call unless the function calling it is 
       checking for health factors being broken
     */
    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        s_DSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountCollateral)
        private
    {
        //CEIの流れに沿っていない(HealthFactorのcheckが後)が、これはガスを節約するために行っている。
        s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        //HealthFactorが1を下回った場合は、revertする
        // _revertIfHealthFactorIsBroken(msg.sender);
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /*
     * Returns: liquidation（清算）にどれだけ近いかを返す。
     * 1を下回ると、清算される。
     */
    function _healthFactor(address user) internal view returns (uint256) {
        //total DSC minted
        //total collateral Value
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        //1000 ETH * 50 = 50,000 / 100 = 500
        //$150 ETH / 100 DSC = 1.5
        //150 * 50 = 7500 / 100 = 75, 75 / 100 = 0.75 < 1

        // $1000 ETH / 100 DSC = 10
        // 1000 * 50 = 50000 / 100 = 500, 500 / 100 = 5 > 1
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
        // return collateralValueInUsd / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        //清算価格が1を下回った場合は、revertする
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreakHealthFactor(userHealthFactor);
        }
    }

    ///////////////////////////////////////
    // Public & External View Functions  //
    ///////////////////////////////////////

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        //price of ETH(token)
        //$/ETH ETH ??
        //$2000 /ETH. $1000 = 0.5 ETH
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        //loop処理で、各トークンから預入量を取得する
        //預入量をUSDに変換する
        //預入量を返す
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        //tokenのUSD価格を取得する
        //amount * USD価格を返す
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        //1ETH = 1000USDとする
        //Chainlinkが返す値は1000 * 1e8となるので、1e18で割る
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    function getCollateralBalanceOfUser(address user, address token) external view returns (uint256) {
        return s_collateralDeposited[user][token];
    }

    function getAccountInformation(address user) external view returns (uint256 totalDscMinted, uint256 collateralValueInUsd) {
        (totalDscMinted, collateralValueInUsd) = _getAccountInformation(user);
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getDsc() external view returns (address) {
        return address(i_dsc);
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }
}
