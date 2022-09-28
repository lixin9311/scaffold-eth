// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetFixedSupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBlacklist.sol";

contract SomeToken is ERC20PresetFixedSupplyUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public counter = 0;
    address public blacklistImplamentation;

    function initialize() public virtual initializer {
        __ERC20PresetFixedSupply_init("Some Token", "SOT", 10000000000000000000000000000, _msgSender());
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

    function _afterTokenTransfer(
        address,
        address,
        uint256
    ) internal virtual override {
        ++counter;
    }

    function updateBlacklistImplamentation(address _blacklistImplamentation) public virtual onlyOwner {
        blacklistImplamentation = _blacklistImplamentation;
    }
}
