pragma solidity ^0.5.0;
// 这个合约是ERC721非同质化代币标准实现
import "../../openzeppelin/token/ERC721/ERC721Full.sol";
// 这个合约是实现可以接收ERC721代币，如果没有这个，当前合约就不能接收ERC721代币
import "../../openzeppelin/token/ERC721/ERC721Holder.sol";
// 序号递增器
import "../../openzeppelin/drafts/Counters.sol";


//全功能ERC721代币（注意：这个合约铸造的ERC721代币的ID是自动生成的，如果要自定义币ID可参考../../openzeppelin/token/ERC721/ERC721Mintable.sol）
contract ERC721FullContract is ERC721Full, ERC721Holder {
    using Counters for Counters.Counter;
	// 单个ERC721代币ID生成器
    Counters.Counter private _tokenIds;

	/**
	 * 合约构造器
	 */
    constructor(
        string memory name, //代币名称
        string memory symbol,//代币缩写
        string memory baseURI//代币基本地址
    // 调用父类ERC721Full构造器    
    ) ERC721Full(name, symbol) public {
        _setBaseURI(baseURI);
    }

    /**
     * 铸造ERC721代币
	 * @param player   代币所有者地址
	 * @param tokenURI 代币信息地址（可以是图片地址）
	 * @return tokenId
	 */
    function awardItem(address player, string memory tokenURI) public returns (uint256) {
	    // tokenId递增
        _tokenIds.increment();
        // 获取当前tokenId
        uint256 newItemId = _tokenIds.current();
		// 铸造ERC721代币
        _mint(player, newItemId);
		// 设置代币信息地址
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}