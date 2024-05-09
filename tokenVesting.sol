// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the owner.
 */
contract TokenVesting is Ownable, ReentrancyGuard {
    IERC20 private _token;

    struct VestingSchedule {
        uint256 start;
        uint256 duration;
        uint256 amountTotal;
        uint256 amountReleased;
        bool isBlacklisted;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    event BeneficiaryAdded(address indexed beneficiary, uint256 start, uint256 duration, uint256 totalAmount);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event BeneficiaryBlacklisted(address indexed beneficiary);
    event BeneficiaryWhitelisted(address indexed beneficiary);

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param tokenAddress address of the ERC20 token contract
     */
    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "TokenVesting: token is the zero address");
        _token = IERC20(tokenAddress);
    }

    /**
     * @notice Adds a beneficiary to the vesting schedule
     * @param beneficiary Address of the beneficiary to whom vested tokens are transferred
     * @param start The time (as Unix time) at which point vesting starts
     * @param duration Duration in seconds of the period in which the tokens will vest
     * @param totalAmount The total amount of tokens to be released at the end of the vesting
     */
    function addBeneficiary(address beneficiary, uint256 start, uint256 duration, uint256 totalAmount) public onlyOwner {
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        require(vestingSchedules[beneficiary].amountTotal == 0, "TokenVesting: beneficiary already added");

        vestingSchedules[beneficiary] = VestingSchedule(start, duration, totalAmount, 0, false);
        emit BeneficiaryAdded(beneficiary, start, duration, totalAmount);
    }

    /**
     * @notice Transfers vested tokens to beneficiary
     * @param beneficiary the address of the beneficiary to whom vested tokens are transferred
     */
    function release(address beneficiary) public nonReentrant {
        require(!vestingSchedules[beneficiary].isBlacklisted, "TokenVesting: beneficiary is blacklisted");
        uint256 unreleased = _releasableAmount(beneficiary);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        vestingSchedules[beneficiary].amountReleased += unreleased;
        _token.transfer(beneficiary, unreleased);

        emit TokensReleased(beneficiary, unreleased);
    }

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet.
     * @param beneficiary address of the beneficiary
     */
    function _releasableAmount(address beneficiary) private view returns (uint256) {
        return _vestedAmount(beneficiary) - vestingSchedules[beneficiary].amountReleased;
    }

    /**
     * @notice Calculates the amount that has already vested.
     * @param beneficiary address of the beneficiary
     */
    function _vestedAmount(address beneficiary) private view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        uint256 totalBalance = schedule.amountTotal;

        if (block.timestamp < schedule.start) {
            return 0;
        } else if (block.timestamp >= schedule.start + schedule.duration) {
            return totalBalance;
        } else {
            uint256 initialUnlock = totalBalance * 15 / 100;
            uint256 postStart = block.timestamp - schedule.start;
            uint256 remainingBalance = totalBalance - initialUnlock;
            uint256 vestingDuration = schedule.duration;

            return initialUnlock + (remainingBalance * postStart / vestingDuration);
        }
    }

    /**
     * @notice Blacklists a beneficiary
     * @param beneficiary address of the beneficiary
     */
    function blacklistBeneficiary(address beneficiary) public onlyOwner {
        vestingSchedules[beneficiary].isBlacklisted = true;
        emit BeneficiaryBlacklisted(beneficiary);
    }

    /**
     * @notice Whitelists a beneficiary
     * @param beneficiary address of the beneficiary
     */
    function whitelistBeneficiary(address beneficiary) public onlyOwner {
        vestingSchedules[beneficiary].isBlacklisted = false;
        emit BeneficiaryWhitelisted(beneficiary);
    }

    /**
     * @dev Set the token for vesting.
     * @param newToken address of the new ERC20 token
     */
    function setToken(address newToken) public onlyOwner {
        require(newToken != address(0), "TokenVesting: new token is the zero address");
        _token = IERC20(newToken);
    }
}
