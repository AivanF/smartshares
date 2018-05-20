pragma solidity ^0.4.23;

import "./SafeMath.sol";


contract SharesTokenInterface {
    function createShare(string _title, uint maxim) external returns(uint);
    function isReady(uint256 _tokenId) public view returns(bool);
    function addMember(uint256 _tokenId, address user, uint value) external returns(bool);
	function totalSupply(uint256 _tokenId) external view returns (uint256);
	function balanceOf(uint256 _tokenId, address _owner) external view returns (uint256);
	function transfer(uint256 _tokenId, address _to, uint256 _value) external returns (bool);
// 	function invest(uint256 _tokenId) payable external;

	event Transfer(uint256 indexed tokenId, address indexed from, address indexed to, uint256 value);
}

contract SharesToken is SharesTokenInterface {
	using SafeMath for uint;
	
	struct Share {
	    string title;
	    uint totalSupply;
	    uint ready;
	    uint membersCount;
	    mapping(uint => address) members;
	    mapping(address => uint) balances;
	    
	    uint maxSingleTransfer;
	    uint maxTotalBalance;
	}
	
	uint internal shares_count = 0;
	mapping(uint => Share) internal allshares;
	
	
	function createShare(string _title, uint maxim) external returns(uint) {
	    uint256 _tokenId = shares_count;
	    shares_count++;
	    allshares[_tokenId].title = _title;
	    allshares[_tokenId].totalSupply = maxim;
	    allshares[_tokenId].ready = 0;
	    return _tokenId;
	}
	
	function isReady(uint256 _tokenId) public view returns(bool) {
	    return (allshares[_tokenId].ready == allshares[_tokenId].totalSupply);
	}
	
	function addMaxSingleTransfer(uint256 _tokenId, uint value) external {
	    allshares[_tokenId].maxSingleTransfer = value;
	}
	
	function addMaxTotalBalance(uint256 _tokenId, uint value) external {
	    allshares[_tokenId].maxTotalBalance = value;
	}
	
	function addMember(uint256 _tokenId, address user, uint value) external returns(bool) {
	    require(allshares[_tokenId].ready + value <= allshares[_tokenId].totalSupply);
	    if (allshares[_tokenId].maxTotalBalance > 0)
	        require(allshares[_tokenId].balances[user] + value <= allshares[_tokenId].maxTotalBalance);
	    
	    allshares[_tokenId].balances[user] += value;
	    allshares[_tokenId].ready += value;
	    allshares[_tokenId].members[allshares[_tokenId].membersCount] = msg.sender;
	    allshares[_tokenId].membersCount++;
	    return true;
	}

 
	/**
	* @dev Gets the total amount of tokens stored by the contract
	* @param _tokenId is subtoken identifier
	* @return representing the total amount of tokens
	*/
	function totalSupply(uint _tokenId) external view returns (uint) {
		return allshares[_tokenId].totalSupply;
	}

	/**
	* @dev Gets the balance of the specified address
	* @param _tokenId is subtoken identifier
	* @param _owner address to query the balance of
	* @return representing the amount owned by the passed address
	*/
	function balanceOf(uint _tokenId, address _owner) external view returns (uint) {
		return allshares[_tokenId].balances[_owner];
	}


	/**
	* @dev transfer token for a specified address
	* @param _tokenId subtoken identifier
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(uint _tokenId, address _to, uint _value) external returns (bool) {
		return transfer_(_tokenId, msg.sender, _to, _value);
	}

	/**
	* @dev Transfer tokens from one address to another
	* @param _tokenId subtoken identifier
	* @param _from The address which you want to send tokens from
	* @param _to The address which you want to transfer to
	* @param _value uint the amount of tokens to be transferred
	*/
	function transfer_(uint _tokenId, address _from, address _to, uint _value) internal returns (bool) {
		require(_from != _to);
		require(isReady(_tokenId));
		if (allshares[_tokenId].maxSingleTransfer > 0)
		    require(_value <= allshares[_tokenId].maxSingleTransfer);
        if (allshares[_tokenId].maxTotalBalance > 0)
		    require(_value <= allshares[_tokenId].maxTotalBalance);
		
		mapping(address => uint) _balances = allshares[_tokenId].balances;
		uint _bfrom = _balances[_from];
		uint _bto = _balances[_to];
		require(_to != address(0));
		require(_value <= _bfrom);
		_balances[_from] = _bfrom.sub(_value);
		_balances[_to] = _bto.add(_value);
		emit Transfer(_tokenId, _from, _to, _value);
		return true;
	}
}