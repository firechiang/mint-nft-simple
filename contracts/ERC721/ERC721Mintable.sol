pragma solidity ^0.5.0;

import "../../openzeppelin/token/ERC721/ERC721Full.sol";
// 自定义ERC721代币ID合约实现
import "../../openzeppelin/token/ERC721/ERC721Mintable.sol";
// 自定义ERC721代币ID的元数据合约实现
import "../../openzeppelin/token/ERC721/ERC721MetadataMintable.sol";
import "../../openzeppelin/token/ERC721/ERC721Holder.sol";
//可自定义ERC721代币ID的ERC721代币合约
contract ERC721MintableContract is ERC721Full, ERC721Mintable, ERC721MetadataMintable, ERC721Holder{
    constructor(
        string memory name, //代币名称
        string memory symbol,//代币缩写
        string memory baseURI//代币基本地址
    ) 
    // 调用父类ERC721Full构造器
    ERC721Full(name, symbol) 
    public {
        _setBaseURI(baseURI);
    }
}