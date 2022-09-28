// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/ERC721PresetUpgradeable.sol";
import "./interfaces/IBlacklist.sol";

contract SomeNFT is ERC721PresetUpgradeable {
    // uint256 public counter = 0;
    address public blacklistImplamentation;

    function initialize() public virtual initializer {
        __ERC721Preset_init("SomeNFT", "NFT", "https://metadata.somenft.io/nft/");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721PresetUpgradeable) {
        if (blacklistImplamentation != address(0)) {
            require(IBlacklist(blacklistImplamentation).isPermitted(_msgSender()), "ERC721: blacklist address");
            require(IBlacklist(blacklistImplamentation).isPermitted(from), "ERC721: blacklist address");
            require(IBlacklist(blacklistImplamentation).isPermitted(to), "ERC721: blacklist address");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // function _afterTokenTransfer(
    //     address,
    //     address,
    //     uint256
    // ) internal virtual override {
    //     ++counter;
    // }

    function updateBlacklistImplamentation(address _blacklistImplamentation) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721: not admin");

        blacklistImplamentation = _blacklistImplamentation;
    }
}
