pragma solidity ^0.5.0;

import "../../openzeppelin/token/ERC721/ERC721Full.sol";
import "../../openzeppelin/token/ERC721/ERC721Pausable.sol";
import "../../openzeppelin/token/ERC721/ERC721Holder.sol";
import "../../openzeppelin/drafts/Counters.sol";
//可暂停铸币的ERC721代币
contract ERC721PausableContract is ERC721Full, ERC721Pausable, ERC721Holder{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory name, //代币名称
        string memory symbol,//代币缩写
        string memory baseURI//代币基本地址
    // 调用父类ERC721Full构造器    
    ) ERC721Full(name, symbol) public {
        _setBaseURI(baseURI);
    }

    function awardItem(address player, string memory tokenURI) public whenNotPaused() returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}