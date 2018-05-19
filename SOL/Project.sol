pragma solidity ^0.4.23;

import "./SafeMath.sol";


contract SharesTokenInterface {
    function createToken(uint256 _tokenId) external returns (bool);
    function addMember(uint256 _tokenId, address user, uint value) external;
	function totalSupply(uint256 _tokenId) external view returns (uint256);
	function balanceOf(uint256 _tokenId, address _owner) external view returns (uint256);
	function transfer(uint256 _tokenId, address _to, uint256 _value) external returns (bool);
	function invest(uint256 _tokenId) payable external;

	event Transfer(uint256 indexed tokenId, address indexed from, address indexed to, uint256 value);
}

contract SharesToken is SharesTokenInterface {
	using SafeMath for uint;
	
	mapping(uint => address) internal members;
	mapping(uint => uint) internal membersCount;
	mapping(uint => mapping(address => uint)) internal balances;
	mapping(uint => uint) internal totalSupply_;
	mapping(uint => uint) internal ready_;
	
	
	function createToken(uint256 _tokenId, uint maxim) external returns (bool) {
	    totalSupply_[_tokenId] = maxim;
	    ready_[_tokenId] = 0;
	}
	
	function addMember(uint256 _tokenId, address user, uint value) external {
	    require(ready_[_tokenId] + value <= totalSupply_[_tokenId]);
	    balances[_tokenId][user] += value;
	    ready_[_tokenId] += value;
	    members[_tokenId] = msg.sender;
	    membersCount[_tokenId]++;
	}

 
	/**
	* @dev Gets the total amount of tokens stored by the contract
	* @param _tokenId is subtoken identifier
	* @return representing the total amount of tokens
	*/
	function totalSupply(uint _tokenId) external view returns (uint) {
		return totalSupply_[_tokenId];
	}

	/**
	* @dev Gets the balance of the specified address
	* @param _tokenId is subtoken identifier
	* @param _owner address to query the balance of
	* @return representing the amount owned by the passed address
	*/
	function balanceOf(uint _tokenId, address _owner) external view returns (uint) {
		return balances[_tokenId][_owner];
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
	
	function checkit() internal view returns (bool) {
	    return true;
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
		require(checkit());
		mapping(address => uint) _balances = balances[_tokenId];
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