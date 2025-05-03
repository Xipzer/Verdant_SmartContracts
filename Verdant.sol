// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/*
 * @author ~ 🅧🅘🅟🅩🅔🅡 ~
 *
 * ██╗░░░██╗███████╗██████╗░██████╗░░█████╗░███╗░░██╗████████╗
 * ██║░░░██║██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗░██║╚══██╔══╝
 * ╚██╗░██╔╝█████╗░░██████╔╝██║░░██║███████║██╔██╗██║░░░██║░░░
 * ░╚████╔╝░██╔══╝░░██╔══██╗██║░░██║██╔══██║██║╚████║░░░██║░░░
 * ░░╚██╔╝░░███████╗██║░░██║██████╔╝██║░░██║██║░╚███║░░░██║░░░
 * ░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░
 * Description: The Official Verdant ($VDNT) Token Contract
 *
 * X: https://x.com/ProjectVerdant
 * Telegram: https://t.me/ProjectVerdant
 * Website: https://projectverdant.com
*/
contract Verdant is Context, IERC20, Ownable {
    using Address for address;

    string public name = "Verdant";
    string public symbol = "VDNT";

    uint public decimals = 18;
    uint public totalSupply = 21000000 * 10 ** decimals;

    uint public swapThresholdMin = totalSupply / 5000;
    uint public swapThresholdMax = totalSupply / 500;

    address public dexPair;
    IUniswapV2Router02 public dexRouter;
    address payable public maintenanceAddress;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowances;

    mapping(address => bool) public isMarketPair;
    mapping(address => bool) private isFeeExempt;

    struct Fees {
        uint inFee;
        uint outFee;
    }

    Fees public fees;

    bool public trading;
    bool public feeStatus;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool public swapAndLiquifyByLimitOnly;

    event FeeStatusUpdated(bool status);
    event FeesUpdated(uint inFee, uint outFee);
    event SwapAndLiquifyStatusUpdated(bool status);
    event SwapAndLiquifyByLimitStatusUpdated(bool status);
    event SwapTokensForETH(uint amountIn, address[] path);

    modifier lockTheSwap
    {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _maintenance) Ownable(msg.sender) {
        dexRouter = IUniswapV2Router02(0xad1eCa41E6F772bE3cb5A48A6141f9bcc1AF9F7c);
        dexPair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        allowances[address(this)][address(dexRouter)] = type(uint).max;

        maintenanceAddress = payable(_maintenance);

        fees.inFee = 1000;
        fees.outFee = 1000;

        trading = false;
        feeStatus = true;
        swapAndLiquifyEnabled = true;
        swapAndLiquifyByLimitOnly = true;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(0)] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[maintenanceAddress] = true;

        isMarketPair[address(dexPair)] = true;

        balances[address(this)] = totalSupply;
        emit Transfer(address(0), address(this), totalSupply);
    }

    function balanceOf(address wallet) public view override returns (uint) {
        return balances[wallet];
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return allowances[owner][spender];
    }

    function getCirculatingSupply() public view returns (uint) {
        return totalSupply - balanceOf(address(0));
    }

    function setMarketPairStatus(address wallet, bool status) external onlyOwner() {
        isMarketPair[wallet] = status;
    }

    function setSwapThresholds(uint swapMin, uint swapMax) external onlyOwner() {
        swapThresholdMin = swapMin;
        swapThresholdMax = swapMax;
    }

    function setSwapAndLiquifyStatus(bool status) external onlyOwner() {
        swapAndLiquifyEnabled = status;
        emit SwapAndLiquifyStatusUpdated(status);
    }

    function setSwapAndLiquifyByLimitStatus(bool status) external onlyOwner() {
        swapAndLiquifyByLimitOnly = status;
        emit SwapAndLiquifyByLimitStatusUpdated(status);
    }

    function setFeesStatus(bool status) external onlyOwner() {
        require(status != feeStatus, "ERROR: Status must not be identical to current!");

        feeStatus = status;
        emit FeeStatusUpdated(status);
    }

    function setFees(uint inFee, uint outFee) external onlyOwner() {
        require(inFee <= 1000 && outFee <= 1000, "ERROR: Maximum directional fee is 10%!");

        fees.inFee = inFee;
        fees.outFee = outFee;
        emit FeesUpdated(inFee, outFee);
    }

    function setupLiquidity() external payable onlyOwner() {
        uint liquidityAmount = (msg.value * 4) / 10;
        uint tokenAmount = msg.value - liquidityAmount;

        dexRouter.addLiquidityETH{ value: liquidityAmount }(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );

        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: tokenAmount }(
            0,
            path,
            owner(),
            block.timestamp
        );
    }

    function enableTrading() external onlyOwner() {
        require(!trading, "ERROR: Trading has already been enabled!");
        trading = true;
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERROR: Approve from the zero address!");
        require(spender != address(0), "ERROR: Approve to the zero address!");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        if (allowances[sender][_msgSender()] != type(uint256).max)
            allowances[sender][_msgSender()] -= amount;

        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        if (inSwapAndLiquify) {
            balances[sender] -= amount;
            balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
        else {
            if (!isFeeExempt[sender] && !isFeeExempt[recipient])
                require(trading, "ERROR: Trading is not enabled!");

            uint contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance >= swapThresholdMin && !isMarketPair[sender] && isMarketPair[recipient] && swapAndLiquifyEnabled) {
                if (swapAndLiquifyByLimitOnly)
                    contractTokenBalance = contractTokenBalance > swapThresholdMax ? swapThresholdMax : contractTokenBalance;
                swapAndLiquify(contractTokenBalance);
            }

            balances[sender] -= amount;
            uint finalAmount = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, recipient, amount);
            balances[recipient] += finalAmount;

            emit Transfer(sender, recipient, finalAmount);
        }
    }

    function takeFee(address from, address to, uint amount) internal returns (uint) {
        uint feeTotal = 0;

        if (feeStatus) {
            if (isMarketPair[from])
                feeTotal = amount * fees.inFee / 10000;
            else if (isMarketPair[to])
                feeTotal = amount * fees.outFee / 10000;
            if (feeTotal > 0) {
                balances[address(this)] += feeTotal;
                emit Transfer(from, address(this), feeTotal);
            }
        }

        return amount - feeTotal;
    }

    function swapAndLiquify(uint amount) private lockTheSwap() {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        try dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            maintenanceAddress,
            block.timestamp
        ){} catch {}
    }

    function withdrawStuckEth() external onlyOwner() {
        payable(msg.sender).call{value: address(this).balance}("");
    }

    receive() external payable {}
}