// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./interfaces/IBlacklist.sol";

contract Blacklist is AccessControlEnumerableUpgradeable, IBlacklist {
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    mapping(address => bool) public isBlacklisted;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
    }

    function blacklist(address[] calldata accounts) external {
        require(hasRole(EDITOR_ROLE, _msgSender()), "Blacklist: not editor");

        for (uint8 i = 0; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = true;
            emit Blacklisted(accounts[i]);
        }
    }

    function unblacklist(address[] calldata accounts) external {
        require(hasRole(EDITOR_ROLE, _msgSender()), "Blacklist: not editor");

        for (uint8 i = 0; i < accounts.length; ++i) {
            isBlacklisted[accounts[i]] = false;
            emit Unblacklisted(accounts[i]);
        }
    }

    function isPermitted(address account) public view returns (bool) {
        return !isBlacklisted[account];
    }
}
