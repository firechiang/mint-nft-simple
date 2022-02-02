//固定总量代币
const ERC721FullContract = artifacts.require("ERC721FullContract"); 

module.exports = function(deployer) {
    deployer.deploy(ERC721FullContract,
    //构造函数的参数（代币名称，简称，代币信息地址）
    "My Game Token","MGT",'https://github.com/Fankouzu/MintCoin/blob/master/');
};