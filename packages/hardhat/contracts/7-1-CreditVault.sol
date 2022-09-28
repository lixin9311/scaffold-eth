// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CreditVault is AccessControlEnumerable, Pausable, EIP712 {
    bytes32 public constant TRUST_SIGNER_ROLE = keccak256("TRUST_SIGNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 private constant TYPEHASH = keccak256("Credential(address account,address token,uint256 tokenId,uint256 amount,uint256 nonce,uint256 expiry)");

    address public superVault;
    uint256 public maxNativeValue;
    uint256 public depositCounter = 0;
    uint256 public withdrawCounter = 0;
    mapping(address => uint8) private _ercVersions; // ercVersion: 1 = ERC20, 2 = ERC721, 3 = ERC1155
    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) private _nonces;

    event Deposit(address indexed account, address indexed token, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed account, address indexed token, uint256 tokenId, uint256 amount, uint256 indexed nonce);
    event AddToken(address indexed token, uint8 ercVersion);

    constructor(
        string memory name,
        string memory version,
        address _superVault,
        uint256 _maxNativeValue
    ) EIP712(name, version) {
        superVault = _superVault;
        maxNativeValue = _maxNativeValue;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    }

    function getNonce(address account) public view virtual returns (uint256 current) {
        current = _nonces[account].current();
    }

    function deposit() public payable virtual whenNotPaused {
        require(superVault != address(0), "CreditVault: superVault is not set");

        _deposit();
        emit Deposit(_msgSender(), address(0), 0, msg.value);
        ++depositCounter;
    }

    function deposit(
        address token,
        uint256 tokenId,
        uint256 amount
    ) public payable virtual whenNotPaused {
        require(superVault != address(0), "CreditVault: superVault is not set");

        if (token == address(0)) {
            tokenId = 0;
            amount = msg.value;
            _deposit();
        } else {
            _deposit(token, tokenId, amount);
        }
        emit Deposit(_msgSender(), token, tokenId, amount);
        ++depositCounter;
    }

    // deposit native cryptocurrency
    function _deposit() internal virtual {
        if (address(this).balance > maxNativeValue) {
            payable(superVault).transfer(address(this).balance - maxNativeValue);
        }
    }

    // deposit tokens
    function _deposit(
        address token,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        uint8 ercVersion = _ercVersions[token];
        require(ercVersion > 0, "CreditVault: token not supported");

        if (ercVersion == 1) {
            require(tokenId == 0, "CreditVault: invalid tokenId");
            IERC20(token).transferFrom(_msgSender(), superVault, amount);
        } else if (ercVersion == 2) {
            require(amount == 1, "CreditVault: invalid amount");
            IERC721(token).transferFrom(_msgSender(), superVault, tokenId);
        } else if (ercVersion == 3) {
            IERC1155(token).safeTransferFrom(_msgSender(), superVault, tokenId, amount, "0x");
        }
    }

    function withdraw(
        address account,
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        bytes memory signature
    ) public virtual whenNotPaused {
        require(superVault != address(0), "CreditVault: superVault is not set");
        require(account != address(0), "CreditVault: invalid account");
        require(block.timestamp <= expiry, "CreditVault: signature expired");
        require(nonce == _useNonce(account), "CreditVault: invalid nonce");
        require(validateTrustSig(account, token, tokenId, amount, nonce, expiry, signature), "CreditVault: invalid signature");

        if (token == address(0)) {
            require(tokenId == 0, "CreditVault: invalid tokenId");
            _withdraw(account, amount);
        } else {
            _withdraw(account, token, tokenId, amount, superVault);
        }
        emit Withdraw(account, token, tokenId, amount, nonce);
        ++withdrawCounter;
    }

    // withdraw native cryptocurrency
    function _withdraw(address account, uint256 amount) internal virtual {
        require(address(this).balance >= amount, "CreditVault: insufficient funds");
        payable(account).transfer(amount);
    }

    // withdraw tokens
    function _withdraw(
        address account,
        address token,
        uint256 tokenId,
        uint256 amount,
        address _superVault
    ) internal virtual {
        uint8 ercVersion = _ercVersions[token];
        require(ercVersion > 0, "CreditVault: token not supported");

        if (ercVersion == 1) {
            require(tokenId == 0, "CreditVault: invalid tokenId");
            IERC20(token).transferFrom(_superVault, account, amount);
        } else if (ercVersion == 2) {
            require(amount == 1, "CreditVault: invalid amount");
            IERC721(token).safeTransferFrom(_superVault, account, tokenId);
        } else if (ercVersion == 3) {
            IERC1155(token).safeTransferFrom(_superVault, account, tokenId, amount, "0x");
        }
    }

    // utils
    function validateTrustSig(
        address account,
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        bytes memory signature
    ) public view virtual returns (bool valid) {
        valid = false;
        address signer = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(TYPEHASH, account, token, tokenId, amount, nonce, expiry))), signature);
        if (hasRole(TRUST_SIGNER_ROLE, signer)) valid = true;
    }

    function _useNonce(address account) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[account];
        current = nonce.current();
        nonce.increment();
    }

    // admin
    function addToken(address token, uint8 ercVersion) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CreditVault: must have admin role");
        require(token != address(0), "CreditVault: invalid token");
        if (ercVersion > 0) {
            _ercVersions[token] = ercVersion;
        } else {
            delete _ercVersions[token];
        }
        emit AddToken(token, ercVersion);
    }

    function withdraw(
        address account,
        address token,
        uint256 tokenId,
        uint256 amount
    ) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CreditVault: must have admin role");
        require(account != address(0), "CreditVault: invalid account");

        _withdraw(account, token, tokenId, amount, address(this));
    }

    function UpdateSuperVault(address _superVault) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CreditVault: must have admin role");
        require(_superVault != address(0), "CreditVault: invalid account");

        superVault = _superVault;
    }

    function UpdateMaxNativeValue(uint256 _maxNativeValue) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CreditVault: must have admin role");

        maxNativeValue = _maxNativeValue;
    }

    // pauser
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "CreditVault: must have pauser role");

        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "CreditVault: must have pauser role");

        _unpause();
    }
}
