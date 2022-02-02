pragma solidity ^0.5.0;

import "./ERC721.sol";
import "../../lifecycle/Pausable.sol";

/**
 * 可暂停铸币的ERC721代币合约实现
 * @title ERC721 Non-Fungible Pausable token
 * @dev ERC721 modified with pausable transfers.
 */
contract ERC721Pausable is ERC721, Pausable {
    function approve(address to, uint256 tokenId) public whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        super.setApprovalForAll(to, approved);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal whenNotPaused {
        super._transferFrom(from, to, tokenId);
    }
}
