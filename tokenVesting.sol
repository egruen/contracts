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
        uint256 amountTotal;
        uint256 amountReleased;
        bool isBlacklisted;
    }

    uint256 public start;
    uint256 public duration;

    mapping(address => VestingSchedule) public vestingSchedules;

    event BeneficiaryAdded(address indexed beneficiary, uint256 totalAmount);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event BeneficiaryBlacklisted(address indexed beneficiary);
    event BeneficiaryWhitelisted(address indexed beneficiary);
    event VestingScheduleUpdated(uint256 start, uint256 duration);

    /**
     * @dev Sets the initial parameters for the vesting contract.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Adds multiple beneficiaries to the vesting schedule in a single transaction.
     * @param beneficiaries Array of addresses of the beneficiaries to whom vested tokens are transferred.
     * @param totalAmounts Array of total amounts of tokens to be vested for each beneficiary.
     */
    function addBeneficiaries(address[] calldata beneficiaries, uint256[] calldata totalAmounts) public onlyOwner {
        require(beneficiaries.length == totalAmounts.length, "TokenVesting: Array lengths do not match");
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address beneficiary = beneficiaries[i];
            uint256 totalAmount = totalAmounts[i];
            require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
            require(vestingSchedules[beneficiary].amountTotal == 0, "TokenVesting: beneficiary already added");
            vestingSchedules[beneficiary] = VestingSchedule(totalAmount, 0, false);
            emit BeneficiaryAdded(beneficiary, totalAmount);
        }
    }

    /**
     * @notice Sets the global vesting schedule for all beneficiaries.
     * @param _start The time (as Unix time) at which point vesting starts.
     * @param _duration Duration in seconds of the period in which the tokens will vest.
     */
    function setVestingSchedule(uint256 _start, uint256 _duration) public onlyOwner {
        start = _start;
        duration = _duration;
        emit VestingScheduleUpdated(_start, _duration);
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

        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalBalance;
        } else {
            uint256 initialUnlock = totalBalance * 15 / 100;
            uint256 postStart = block.timestamp - start;
            uint256 remainingBalance = totalBalance - initialUnlock;
            uint256 vestingDuration = duration;

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

    function ownerWithdraw(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "TokenVesting: Amount must be greater than 0");
       
        _token.transfer(owner(), amount);
    }

}
