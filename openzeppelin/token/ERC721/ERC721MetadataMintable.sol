pragma solidity ^0.5.0;

import "./ERC721Metadata.sol";
import "../../access/roles/MinterRole.sol";


/**
 * 自定义币ID铸造ERC721代币元数据合约实现（这个合约一般给最下面的合约继承就好）
 * @title ERC721MetadataMintable
 * @dev ERC721 minting logic with metadata.
 */
contract ERC721MetadataMintable is ERC721, ERC721Metadata, MinterRole {
    /**
	 * 铸造币
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param tokenURI The token URI of the minted token.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return true;
    }
}
