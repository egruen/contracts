// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";


// Custom error for mint cap 
error MintCapExceeded(uint256 requestedAmount, uint256 cap, uint256 alreadyMinted);

/**
 * @title CADAI Token (CADAI)
 * @dev Implementation of a custom ERC20 Token for CADAICO with burnable, ownable, pausability, and permit extensions.
 * The token has a capped max total supply, with minting capabilities restricted to the owner.
 * It is a wrapped version of the native CADAI token.
 */
contract CADAICO is Context, ERC20, ERC20Permit, ERC20Burnable, Ownable2Step, ERC20Pausable {

    uint256 public immutable MAX_TOTAL_SUPPLY = 100_000_000 * 10 ** 18; // Max supply capped at 100 million tokens.
    uint256 public totalMinted; // Total amount of tokens that have been minted.
    uint256 public constant INITIAL_MINT_AMOUNT = 10_000_000 * 10 ** 18; // Initial amount of tokens minted to the deployer.

    /**
     * @dev Sets the initial values for {name}, {symbol}, and {MAX_TOTAL_SUPPLY}.
     * Mints initial tokens to the deploying address.
     *
     * @param initialOwner The account that will be the initial owner of the token.
     */
    constructor(
        address initialOwner
    ) ERC20("CADAICO", "CADAI") Ownable(initialOwner) ERC20Permit("CADAICO") {
        _mint(initialOwner, INITIAL_MINT_AMOUNT);
        totalMinted = INITIAL_MINT_AMOUNT; // Update the total minted tokens
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

        totalMinted += amount; // Update the total minted tokens
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers. Can only be called by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers. Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        // Implement logic for your specific requirements
        super._update(from, to, value);
    }

}
