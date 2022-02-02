pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
// ERC721标准接口文件
import "./IERC721.sol";
// 可以接收ERC721代币标准接口文件
import "./IERC721Receiver.sol";
import "../../math/SafeMath.sol";
// 检查地址是不是合约地址的工具类
import "../../utils/Address.sol";
// 序号递增器
import "../../drafts/Counters.sol";
// ERC165标准（该标准的功能是可以检测某一个合约里面是否实现了某些函数）
import "../../introspection/ERC165.sol";

/**
 * ERC721非同质化代币标准实现
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    // 运算工具
    using SafeMath for uint256;
	// 检测地址是否是合约地址
    using Address for address;
	// 序号递增器
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`（就是这个东西的值，再取前16位，用途是检测某个合约是否可以接收ERC721代币）
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
	// 代币ID属于那个用户地址
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
	// 代币ID授权给了某个用户地址
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
	// 用户地址所拥有的币总量计数器
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
	// 某个地址是否将其所有代币授权给某个地址
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
	 *     第一步运算
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
	 *     得到值之后再运算
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
	 *     最后得到的值是 0x80ac58cd
	 *
	 * 这个的作用是别的合约可以检测当前合约是否支持上面一系列的函数（这个就是给ERC165标准实现用的）
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

	/**
	 * 构造器
	 */
    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
		// 注册ERC165标准（当前合约是支持ERC721基础标准相关接口的）
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
	 * 查询某个地址所拥有的ERC721代币数量
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
	 * 查询ERC721代币属于哪个地址
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
	 * 授权转移
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
	 * 查询某个代币授权给了哪个地址
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
	 * 是否将当前调用者地址上所有ERC721代币授权给to地址
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
	 * 某个地址上的所有ERC721代币是否全部授权给某个地址
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
	 * 代币转移（需先授权）
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
	 * 代币转移，给对方是合约地址调用
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
	 * 代币转移，给对方是合约地址调用
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
	    // 验证是否授权
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
		// 转移
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
	 * 代币转移
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
	    // 代币转移
        _transferFrom(from, to, tokenId);
		// 验证对方地址是否可以接收ERC721代币（这个验证放到后面是为了节省Gas，上一步如果没有成功事务也就回滚了）
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
	 * 验证ERC721代币是否存在
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
	 * 验证地址是否拥有某个ERC721代币
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
	 * 安全铸造代币
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
	 * 安全铸造代币
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
		// 验证对方地址是否可以接收ERC721代币（这个验证放到后面是为了节省Gas，上一步如果没有成功事务也就回滚了）
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
	 * 铸造代币
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
	    // 验证to地址不为空
        require(to != address(0), "ERC721: mint to the zero address");
		// 验证币ID是否存在
        require(!_exists(tokenId), "ERC721: token already minted");
        // ERC721币属于to地址
        _tokenOwner[tokenId] = to;
		// to地址持币数量递增
        _ownedTokensCount[to].increment();
        // 发送事件
        emit Transfer(address(0), to, tokenId);
    }

    /**
	 * ERC721代币销毁
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
	    // 验证代币持有者是否是自己
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");
        // 清空授权
        _clearApproval(tokenId);
        // 用户持币数量递减
        _ownedTokensCount[owner].decrement();
		// ERC721代币ID持有者为空
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
	 * ERC721代币销毁（销毁自己的代币）
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
	 * 代币转移
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
	    // 验证代币持有者是from递增
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
		// 验证to地址不为空
        require(to != address(0), "ERC721: transfer to the zero address");
        // 清空授权
        _clearApproval(tokenId);
        // from地址持币数量递减
        _ownedTokensCount[from].decrement();
		// to地址持币数量递增
        _ownedTokensCount[to].increment();
        // 币的持有者为to地址
        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
	 * 验证对方地址是否可以接收ERC721代币
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERC721` contract and its use is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
	    // to地址是否合约地址，如果不是合约地址直接返回True
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
		// 调用对方合约里面的IERC721Receiver函数，也就是验证对方的合约是否可以接收ERC721代币
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
		// 调用不成功
        if (!success) {
		    // 返回值的长度大于0
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
				// 通过内联汇编解析返回值
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
		// 调用成功	
        } else {
		    // 解码返回值
            bytes4 retval = abi.decode(returndata, (bytes4));
			// 解码后的返回值是否等于 _ERC721_RECEIVED 常量值
            return (retval == _ERC721_RECEIVED);
        }
    }

    /**
	 * 清空授权
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}
