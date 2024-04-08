// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title Wrapped CADAI Token (wCADAI)
 * @dev Implementation of a custom ERC20 Token for CADAICO with burnable, ownable, and permit extensions.
 * The token has a capped max total supply, with minting capabilities restricted to the owner.
 * It is a wrapped version of the native CADAI token.
 */
contract CADAICO is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    uint256 private MAX_TOTAL_SUPPLY; // Max supply capped at 100 million tokens.

    /**
     * @dev Sets the initial values for {name}, {symbol}, and {MAX_TOTAL_SUPPLY}.
     * Mints initial tokens to the deploying address.
     *
     * @param initialOwner The account that will be the initial owner of the token.
     */
    constructor(
        address initialOwner
    ) ERC20("CADAICO", "wCADAI") Ownable(initialOwner) ERC20Permit("Cadaico") {
        MAX_TOTAL_SUPPLY = 100000000 * 10 ** decimals(); // Defines the max total supply.
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mints initial supply.
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
    function mint(address to, uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= MAX_TOTAL_SUPPLY,
            "Minting would exceed max total supply"
        );
        _mint(to, amount);
    }
}
