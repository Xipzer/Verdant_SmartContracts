// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @author ~ 🅧🅘🅟🅩🅔🅡 ~
 *
 * ██╗░░░██╗███████╗██████╗░██████╗░░█████╗░███╗░░██╗████████╗
 * ██║░░░██║██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗░██║╚══██╔══╝
 * ╚██╗░██╔╝█████╗░░██████╔╝██║░░██║███████║██╔██╗██║░░░██║░░░
 * ░╚████╔╝░██╔══╝░░██╔══██╗██║░░██║██╔══██║██║╚████║░░░██║░░░
 * ░░╚██╔╝░░███████╗██║░░██║██████╔╝██║░░██║██║░╚███║░░░██║░░░
 * ░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░
 * Description: The Official Verdant World LP Lock Contract
 *
 * X: https://x.com/ProjectVerdant
 * Telegram: https://t.me/ProjectVerdant
 * Website: https://projectverdant.com
*/
contract LiquidityLocker is Ownable {
    IERC20 public lpToken;
    uint256 public unlockTime;
    uint256 public lockedAmount;
    
    event LiquidityLocked(uint256 amount, uint256 unlockTime);
    event LiquidityWithdrawn(uint256 amount);
    
    /**
     * @dev Initialize the contract with owner as the deployer
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Get remaining time until unlock in seconds
     * @return Seconds until unlock (0 if already unlocked)
     */
    function getRemainingTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }
    
    /**
     * @dev Lock LP tokens in the contract
     * @param _lpToken Address of the LP token
     * @param _amount Amount of LP tokens to lock
     * @param _unlockTime Timestamp when tokens can be withdrawn
     */
    function lockLiquidity(address _lpToken, uint256 _amount, uint256 _unlockTime) external onlyOwner {
        require(_lpToken != address(0), "Invalid LP token address");
        require(_amount > 0, "Amount must be greater than 0");
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        require(lockedAmount == 0, "Liquidity already locked");
        
        lpToken = IERC20(_lpToken);
        unlockTime = _unlockTime;
        lockedAmount = _amount;
        
        require(lpToken.transferFrom(msg.sender, address(this), _amount), "LP token transfer failed");
        emit LiquidityLocked(_amount, _unlockTime);
    }
    
    /**
     * @dev Add more LP tokens to an existing lock
     * @param _amount Additional amount of LP tokens to lock
     */
    function addLiquidity(uint256 _amount) external onlyOwner {
        require(address(lpToken) != address(0), "No liquidity locked yet");
        require(_amount > 0, "Amount must be greater than 0");
        require(block.timestamp < unlockTime, "Unlock time has passed");

        lockedAmount += _amount;

        require(lpToken.transferFrom(msg.sender, address(this), _amount), "LP token transfer failed");
        emit LiquidityLocked(_amount, unlockTime);
    }
    
    /**
     * @dev Withdraw LP tokens after unlock time
     */
    function withdrawLiquidity() external onlyOwner {
        require(block.timestamp >= unlockTime, "Tokens are still locked");
        require(lockedAmount > 0, "No liquidity to withdraw");
        
        uint256 amount = lockedAmount;
        lockedAmount = 0;
        
        require(lpToken.transfer(msg.sender, amount), "LP token transfer failed");
        emit LiquidityWithdrawn(amount);
    }
    
    /**
     * @dev Check if liquidity is currently locked
     * @return True if liquidity is locked, false otherwise
     */
    function isLocked() external view returns (bool) {
        return lockedAmount > 0 && block.timestamp < unlockTime;
    }
    
    /**
     * @dev Emergency function to recover other tokens accidentally sent to the contract
     * @param _token Address of the token to recover
     * @param _amount Amount of tokens to recover
     */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(lpToken) || block.timestamp >= unlockTime, "Cannot withdraw locked LP tokens");
        require(IERC20(_token).transfer(msg.sender, _amount), "Token transfer failed");
    }
}