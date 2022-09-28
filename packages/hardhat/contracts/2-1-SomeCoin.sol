// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBlacklist.sol";

contract SomeCoin is ERC20PresetMinterPauserUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public blacklistImplamentation;

    function initialize() public virtual initializer {
        __ERC20PresetMinterPauser_init("Some Coin", "SOC");
        __Ownable_init_unchained();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (blacklistImplamentation != address(0)) {
            require(IBlacklist(blacklistImplamentation).isPermitted(_msgSender()), "ERC20: blacklist address");
            require(IBlacklist(blacklistImplamentation).isPermitted(from), "ERC20: blacklist address");
            require(IBlacklist(blacklistImplamentation).isPermitted(to), "ERC20: blacklist address");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function updateBlacklistImplamentation(address _blacklistImplamentation) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20: not admin");

        blacklistImplamentation = _blacklistImplamentation;
    }
}
