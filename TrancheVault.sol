// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* * ============================================================
 * 🏗️ PROJECT: RWA Tranche Protocol
 * 👨‍💻 AUTHOR: Jieao Liu
 * 📝 NOTE: This file contains both the Protocol Logic and 
 * the Mock Asset for easy testing and verification.
 * ============================================================
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ==========================================
// 1️⃣ The Mock Asset (模拟的 USDT)
// ==========================================
contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "mUSDT") {
        // 部署时给自己发 100 万枚，方便测试
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    // 公开的印钞功能 (Faucets)
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// ==========================================
// 2️⃣ The Core Protocol (分级资金池核心逻辑)
// ==========================================
contract TrancheVault is Ownable {
    
    // --- Core Assets ---
    IERC20 public usdt; 

    // --- State Variables ---
    uint256 public totalSeniorDeposit;
    uint256 public totalJuniorDeposit;
    
    mapping(address => uint256) public seniorBalances;
    mapping(address => uint256) public juniorBalances;

    // --- Settlement Data ---
    uint256 public finalSeniorPayout; 
    uint256 public finalJuniorPayout; 

    // --- Configuration ---
    uint256 public constant SENIOR_APR_PERCENT = 5; 
    bool public isRoundClosed = false;

    // --- Events (Added for better tracking) ---
    event Deposit(address indexed user, uint256 amount, uint8 trancheType);
    event RoundClosed(uint256 seniorPayout, uint256 juniorPayout);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _usdtTokenAddress) Ownable(msg.sender) {
        usdt = IERC20(_usdtTokenAddress);
    }

    // [Deposit] User deposits USDT (0=Senior, 1=Junior)
    function deposit(uint256 amount, uint8 trancheType) external {
        require(!isRoundClosed, "Round closed");
        require(amount > 0, "Amount > 0");
        
        bool success = usdt.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        if (trancheType == 0) {
            seniorBalances[msg.sender] += amount;
            totalSeniorDeposit += amount;
        } else if (trancheType == 1) {
            juniorBalances[msg.sender] += amount;
            totalJuniorDeposit += amount;
        } else {
            revert("Invalid tranche type");
        }
        
        emit Deposit(msg.sender, amount, trancheType);
    }

    // [Settlement] Admin closes the round and distributes yield
    function closeRoundAndDistribute() external onlyOwner {
        require(!isRoundClosed, "Already closed");
        
        uint256 currentBalance = usdt.balanceOf(address(this));
        
        // Calculate Senior target: Principal + 5% Interest
        uint256 expectedSeniorInterest = (totalSeniorDeposit * SENIOR_APR_PERCENT) / 100;
        uint256 seniorTarget = totalSeniorDeposit + expectedSeniorInterest;

        // Waterfall Logic
        if (currentBalance >= seniorTarget) {
            finalSeniorPayout = seniorTarget;
            finalJuniorPayout = currentBalance - seniorTarget; 
        } else {
            finalSeniorPayout = currentBalance;
            finalJuniorPayout = 0;
        }
        
        isRoundClosed = true;
        emit RoundClosed(finalSeniorPayout, finalJuniorPayout);
    }

    // [Withdraw] User claims principal + yield
    function withdraw() external {
        require(isRoundClosed, "Round not closed");

        uint256 amountToReceive = 0;

        // Calculate Senior Share
        uint256 sBalance = seniorBalances[msg.sender];
        if (sBalance > 0 && totalSeniorDeposit > 0) {
            uint256 share = (sBalance * finalSeniorPayout) / totalSeniorDeposit;
            amountToReceive += share;
            seniorBalances[msg.sender] = 0;
        }

        // Calculate Junior Share
        uint256 jBalance = juniorBalances[msg.sender];
        if (jBalance > 0 && totalJuniorDeposit > 0) {
            uint256 share = (jBalance * finalJuniorPayout) / totalJuniorDeposit;
            amountToReceive += share;
            juniorBalances[msg.sender] = 0;
        }

        require(amountToReceive > 0, "Nothing to withdraw");

        bool success = usdt.transfer(msg.sender, amountToReceive);
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amountToReceive);
    }
}
