pragma solidity ^0.5.0;

// ERC721标准实现
import "./ERC721.sol";
// ERC721枚举实现合约
import "./ERC721Enumerable.sol";
// ERC721元数据实现合约
import "./ERC721Metadata.sol";

/**
 * ERC721基础标准实现在 ERC721.sol 合约里面
 * @title Full ERC721 Token
 * @dev This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    /**
	 * @param name 合约币名称
	 * @param symbol 合约币简称
	 */
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}
