pragma solidity ^0.5.0;
// 基础ERC721标准实现
import "./ERC721.sol";
// 铸造权限相关合约实现
import "../../access/roles/MinterRole.sol";

/**
 * 可铸造ERC721代币合约实现，再基础的ERC721标准上面做了一些扩展，代币的ID可以自己传，而不是自动递增
 * 注意：如果是要部署可以自定义币ID的ERC721合约，就用这个
 * @title ERC721Mintable
 * @dev ERC721 minting logic.
 */
contract ERC721Mintable is ERC721, MinterRole {
    /**
	 * 铸造代币（tokenId自己传）
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted token.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    /**
	 * 安全铸造（会验证对方地址是否是合约地址，其实是会验证对方地址是否可接收ERC721代币）
     * @dev Function to safely mint tokens.
     * @param to The address that will receive the minted token.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function safeMint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _safeMint(to, tokenId);
        return true;
    }

    /**
	 * 安全铸造（会验证对方地址是否是合约地址，其实是会验证对方地址是否可接收ERC721代币）
     * @dev Function to safely mint tokens.
     * @param to The address that will receive the minted token.
     * @param tokenId The token id to mint.
     * @param _data bytes data to send along with a safe transfer check.
     * @return A boolean that indicates if the operation was successful.
     */
    function safeMint(address to, uint256 tokenId, bytes memory _data) public onlyMinter returns (bool) {
        _safeMint(to, tokenId, _data);
        return true;
    }
}
