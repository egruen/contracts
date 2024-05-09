// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This extension of the {Ownable} contract includes a two-step mechanism to transfer
 * ownership, where the new owner must call {acceptOwnership} in order to replace the
 * old one. This can help prevent common mistakes, such as transfers of ownership to
 * incorrect accounts, or to contracts that are unable to interact with the
 * permission system.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

pragma solidity 0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";

// custom error for mint cap 
error MintCapExceeded(uint256 requestedAmount, uint256 cap, uint256 alreadyMinted);

/**
 * @title Wrapped CADAI Token (wCADAI)
 * @dev Implementation of a custom ERC20 Token for CADAICO with burnable, ownable, and permit extensions.
 * The token has a capped max total supply, with minting capabilities restricted to the owner.
 * It is a wrapped version of the native CADAI token.
 */
contract CADAICO is Context, ERC20, ERC20Permit, ERC20Burnable, Ownable2Step {

    uint256 public immutable MAX_TOTAL_SUPPLY = 100_000_000 * 10 ** 18; // Max supply capped at 100 million tokens.
    uint256 public totalMinted; // Total amount of tokens that have been minted.
    uint256 public constant initialMint = 10_000_000 * 10 ** 18; // Initial amount of tokens minted to the deployer.

    /**
     * @dev Sets the initial values for {name}, {symbol}, and {MAX_TOTAL_SUPPLY}.
     * Mints initial tokens to the deploying address.
     *
     * @param initialOwner The account that will be the initial owner of the token.
     */
    constructor(
        address initialOwner
    ) ERC20("CADAICO", "wCADAI") Ownable(initialOwner) ERC20Permit("CADAICO") {
        _mint(initialOwner, initialMint);
        totalMinted = initialMint; // Update the total minted tokens
    }

        /**
     * @dev Overrides the renounceOwnership() function to reject any transaction, to ensure functionality of the token
     */

    function renounceOwnership() public view virtual override onlyOwner {
        revert("Renouncing ownership is disabled");
    }

    /**
     * @dev Mints tokens to the specified address, ensuring the total supply does not exceed the max cap.
     * Can only be called by the contract owner.
     *
     * Requirements:
     * - `to` cannot be the zero address.
     * - the total token supply after minting must not exceed the {MAX_TOTAL_SUPPLY}.
     *
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */

    

    function mint(address to, uint256 amount) external onlyOwner {
        if (totalMinted + amount > MAX_TOTAL_SUPPLY) 
            revert MintCapExceeded(amount, MAX_TOTAL_SUPPLY, totalMinted);

        totalMinted += amount; // update the total minted tokens
        _mint(to, amount);
    }
}