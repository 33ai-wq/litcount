// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title LitCount Pool - Save & Win DeFi Pool
/// @notice Pool staking mechanism: stake zkLTC, win jackpot or earn base reward
/// @dev "Save & Win" model: 70% jackpot winner | 20% all stakers | 10% protocol
contract LitCountPool is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ─── Constants ────────────────────────────────────────────────
    uint256 public constant STAKE_AMOUNT     = 0.1 ether;   // 0.1 zkLTC per user
    uint256 public constant POOL_DURATION    = 21 hours;    // pool open period
    uint256 public constant DRAW_WINDOW      = 21 minutes;  // draw/cooldown period
    uint256 public constant MIN_USERS        = 21;          // minimum participants

    uint256 public constant JACKPOT_BPS      = 7000;        // 70% to winner
    uint256 public constant STAKER_BPS       = 2000;        // 20% shared to all
    uint256 public constant PROTOCOL_BPS     = 1000;        // 10% protocol fee
    uint256 public constant BPS_DENOMINATOR  = 10000;

    // ─── State ────────────────────────────────────────────────────
    IERC20 public immutable zkLTCToken;
    address public protocolTreasury;

    uint256 public currentPoolId;
    uint256 public poolStartTime;
    bool    public isDrawPhase;         // true = 21-min draw window active
    bool    public drawExecuted;        // winner has been picked this round

    address[] public participants;
    mapping(address => bool) public hasJoined;
    mapping(address => uint256) public stakedAmount;

    address public lastWinner;
    uint256 public lastJackpot;
    uint256 public lastStakerReward;    // per-user staker reward last round

    // ─── Pool History ─────────────────────────────────────────────
    struct PoolResult {
        uint256 poolId;
        address winner;
        uint256 jackpot;
        uint256 stakerRewardPerUser;
        uint256 totalParticipants;
        uint256 totalPool;
        uint256 timestamp;
        bool    drawHeld;               // false = not enough users
    }
    PoolResult[] public poolHistory;

    // ─── Events ───────────────────────────────────────────────────
    event Joined(address indexed user, uint256 poolId, uint256 totalParticipants);
    event DrawPhaseStarted(uint256 poolId, uint256 participants, uint256 timestamp);
    event DrawExecuted(uint256 poolId, address winner, uint256 jackpot, uint256 stakerRewardPerUser);
    event DrawSkipped(uint256 poolId, uint256 participants, string reason);
    event PoolReset(uint256 newPoolId, uint256 timestamp);
    event RewardClaimed(address indexed user, uint256 amount);

    // ─── Constructor ──────────────────────────────────────────────
    constructor(address _zkLTCToken, address _treasury) Ownable(msg.sender) {
        require(_zkLTCToken  != address(0), "LitCount: invalid token");
        require(_treasury    != address(0), "LitCount: invalid treasury");
        zkLTCToken       = IERC20(_zkLTCToken);
        protocolTreasury = _treasury;
        poolStartTime    = block.timestamp;
        currentPoolId    = 1;
    }

    // ─── User Actions ─────────────────────────────────────────────

    /// @notice Join the current pool by staking 0.1 zkLTC
    function joinPool() external nonReentrant whenNotPaused {
        require(!isDrawPhase,         "LitCount: Draw phase active, pool closed");
        require(!hasJoined[msg.sender], "LitCount: Already in this pool");
        require(
            block.timestamp < poolStartTime + POOL_DURATION,
            "LitCount: Pool duration ended, trigger draw first"
        );

        // Transfer 0.1 zkLTC from user
        zkLTCToken.safeTransferFrom(msg.sender, address(this), STAKE_AMOUNT);

        hasJoined[msg.sender]    = true;
        stakedAmount[msg.sender] = STAKE_AMOUNT;
        participants.push(msg.sender);

        emit Joined(msg.sender, currentPoolId, participants.length);
    }

    // ─── Pool Lifecycle ───────────────────────────────────────────

    /// @notice Called after 21 hours to start the draw phase
    /// @dev Anyone can call this — permissionless trigger
    function triggerDrawPhase() external nonReentrant whenNotPaused {
        require(!isDrawPhase, "LitCount: Already in draw phase");
        require(
            block.timestamp >= poolStartTime + POOL_DURATION,
            "LitCount: Pool still running"
        );

        isDrawPhase   = true;
        drawExecuted  = false;

        emit DrawPhaseStarted(currentPoolId, participants.length, block.timestamp);
    }

    /// @notice Execute the draw during the 21-minute window
    /// @dev Uses pseudo-random (safe for testnet; use Chainlink VRF on mainnet)
    function executeDraw() external nonReentrant whenNotPaused {
        require(isDrawPhase,    "LitCount: Not in draw phase");
        require(!drawExecuted,  "LitCount: Draw already executed");
        require(
            block.timestamp <= poolStartTime + POOL_DURATION + DRAW_WINDOW,
            "LitCount: Draw window expired"
        );

        uint256 count = participants.length;

        // ── Not enough users ──────────────────────────────────────
        if (count < MIN_USERS) {
            poolHistory.push(PoolResult({
                poolId:               currentPoolId,
                winner:               address(0),
                jackpot:              0,
                stakerRewardPerUser:  0,
                totalParticipants:    count,
                totalPool:            count * STAKE_AMOUNT,
                timestamp:            block.timestamp,
                drawHeld:             false
            }));
            emit DrawSkipped(currentPoolId, count, "Minimum 21 users not reached");
            _resetPoolContinue(); // keep participants, just reset timer
            return;
        }

        // ── Enough users — pick winner ────────────────────────────
        drawExecuted = true;

        uint256 totalPool   = count * STAKE_AMOUNT;
        uint256 jackpot     = (totalPool * JACKPOT_BPS)   / BPS_DENOMINATOR;
        uint256 stakerTotal = (totalPool * STAKER_BPS)    / BPS_DENOMINATOR;
        uint256 protocolFee = (totalPool * PROTOCOL_BPS)  / BPS_DENOMINATOR;
        uint256 stakerEach  = stakerTotal / count;

        // Pseudo-random winner (testnet only)
        uint256 randomIndex = _pseudoRandom(count);
        address winner      = participants[randomIndex];

        lastWinner          = winner;
        lastJackpot         = jackpot;
        lastStakerReward    = stakerEach;

        // Send jackpot to winner
        zkLTCToken.safeTransfer(winner, jackpot);

        // Send protocol fee
        zkLTCToken.safeTransfer(protocolTreasury, protocolFee);

        // Send staker reward to each participant
        // (skip winner since they got jackpot — or include, design choice: include all)
        for (uint256 i = 0; i < count; i++) {
            if (stakerEach > 0) {
                zkLTCToken.safeTransfer(participants[i], stakerEach);
            }
        }

        // Record history
        poolHistory.push(PoolResult({
            poolId:               currentPoolId,
            winner:               winner,
            jackpot:              jackpot,
            stakerRewardPerUser:  stakerEach,
            totalParticipants:    count,
            totalPool:            totalPool,
            timestamp:            block.timestamp,
            drawHeld:             true
        }));

        emit DrawExecuted(currentPoolId, winner, jackpot, stakerEach);

        // Full reset for new pool
        _resetPoolFull();
    }

    /// @notice Called after draw window expires without execution
    /// @dev Safety valve — anyone can reset if executeDraw wasn't called
    function forceReset() external nonReentrant whenNotPaused {
        require(isDrawPhase, "LitCount: Not in draw phase");
        require(
            block.timestamp > poolStartTime + POOL_DURATION + DRAW_WINDOW,
            "LitCount: Draw window still open"
        );
        // If not executed — refund all stakes (safety)
        if (!drawExecuted) {
            _refundAll();
        }
        _resetPoolFull();
    }

    // ─── Internal Helpers ─────────────────────────────────────────

    /// @dev Reset timer but KEEP participants (for <21 users case)
    function _resetPoolContinue() internal {
        isDrawPhase   = false;
        drawExecuted  = false;
        poolStartTime = block.timestamp; // new 21-hour window
        currentPoolId++;
        emit PoolReset(currentPoolId, block.timestamp);
    }

    /// @dev Full reset — clear all participants (after successful draw or refund)
    function _resetPoolFull() internal {
        // Clear mappings
        for (uint256 i = 0; i < participants.length; i++) {
            delete hasJoined[participants[i]];
            delete stakedAmount[participants[i]];
        }
        delete participants;
        isDrawPhase   = false;
        drawExecuted  = false;
        poolStartTime = block.timestamp;
        currentPoolId++;
        emit PoolReset(currentPoolId, block.timestamp);
    }

    /// @dev Refund all staked amounts (used in forceReset)
    function _refundAll() internal {
        for (uint256 i = 0; i < participants.length; i++) {
            address user = participants[i];
            uint256 amount = stakedAmount[user];
            if (amount > 0) {
                zkLTCToken.safeTransfer(user, amount);
            }
        }
    }

    /// @dev Pseudo-random for testnet. Use Chainlink VRF on mainnet.
    function _pseudoRandom(uint256 count) internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    participants.length,
                    msg.sender
                )
            )
        ) % count;
    }

    // ─── View Functions ───────────────────────────────────────────

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    function getParticipantCount() external view returns (uint256) {
        return participants.length;
    }

    function getPoolStatus() external view returns (
        uint256 poolId,
        uint256 participantCount,
        uint256 totalStaked,
        uint256 timeLeft,
        bool    inDrawPhase,
        uint256 jackpotEstimate,
        uint256 stakerRewardEstimate
    ) {
        poolId           = currentPoolId;
        participantCount = participants.length;
        totalStaked      = participants.length * STAKE_AMOUNT;
        uint256 endTime  = poolStartTime + POOL_DURATION;
        timeLeft         = block.timestamp >= endTime ? 0 : endTime - block.timestamp;
        inDrawPhase      = isDrawPhase;

        uint256 pool     = participantCount * STAKE_AMOUNT;
        jackpotEstimate          = (pool * JACKPOT_BPS)  / BPS_DENOMINATOR;
        stakerRewardEstimate     = participantCount > 0
            ? ((pool * STAKER_BPS) / BPS_DENOMINATOR) / participantCount
            : 0;
    }

    function getPoolHistory() external view returns (PoolResult[] memory) {
        return poolHistory;
    }

    function getDrawPhaseTimeLeft() external view returns (uint256) {
        if (!isDrawPhase) return 0;
        uint256 drawEnd = poolStartTime + POOL_DURATION + DRAW_WINDOW;
        if (block.timestamp >= drawEnd) return 0;
        return drawEnd - block.timestamp;
    }

    // ─── Admin ────────────────────────────────────────────────────

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "LitCount: invalid treasury");
        protocolTreasury = _treasury;
    }

    /// @notice Emergency withdrawal (only when paused)
    function emergencyWithdraw() external onlyOwner whenPaused {
        uint256 balance = zkLTCToken.balanceOf(address(this));
        zkLTCToken.safeTransfer(owner(), balance);
    }
}
