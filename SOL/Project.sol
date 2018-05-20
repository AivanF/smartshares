pragma solidity ^0.4.23;

import "./SafeMath.sol";


contract SharesTokenInterface {
	function createShare(string _title, uint maxim, uint check) external returns(uint);
	function getTitle(uint _tokenId) external view returns(string);
	function isReady(uint _tokenId) public view returns(bool);
	function isClean(uint _tokenId) public view returns(bool);
	function addMember(uint _tokenId, address user, uint value) external returns(bool);
	function totalSupply(uint _tokenId) external view returns (uint);
	function getMembersCount(uint _tokenId) public view returns(uint);
	function getMember(uint _tokenId, uint ind) public view returns(address);
	function balanceOf(uint _tokenId, address _owner) external view returns (uint);
	function transfer(uint _tokenId, address _to, uint _value) external returns (bool);
	function acceptDividends(uint _tokenId) payable external;

	event ShareCreated(uint indexed tokenId, uint check);
    event AcceptDividends(uint indexed tokenId, uint256 value);
	event Transfer(uint indexed tokenId, address indexed from, address indexed to, uint value);
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
	
	
	function createShare(string _title, uint maxim, uint check) external returns(uint) {
		shares_count++;
		uint _tokenId = shares_count;
		allshares[_tokenId].title = _title;
		allshares[_tokenId].totalSupply = maxim;
		allshares[_tokenId].ready = 0;
		emit ShareCreated(_tokenId, check);
		return _tokenId;
	}
	
	function getTitle(uint _tokenId) external view returns(string) {
		return allshares[_tokenId].title;
	}
	
	function isReady(uint _tokenId) public view returns(bool) {
		return (allshares[_tokenId].ready == allshares[_tokenId].totalSupply);
	}
	
	function isClean(uint _tokenId) public view returns(bool) {
		return (allshares[_tokenId].ready == 0);
	}
	
	function addMaxSingleTransfer(uint _tokenId, uint value) external returns(bool) {
		require(isClean(_tokenId));
		allshares[_tokenId].maxSingleTransfer = value;
		return true;
	}
	
	function addMaxTotalBalance(uint _tokenId, uint value) external returns(bool) {
		require(isClean(_tokenId));
		allshares[_tokenId].maxTotalBalance = value;
		return true;
	}
	
	function addMember(uint _tokenId, address user, uint value) external returns(bool) {
		return addMember_(_tokenId, user, value);
	}
	
	function addMember_(uint _tokenId, address user, uint value) internal returns(bool) {
		require(allshares[_tokenId].ready + value <= allshares[_tokenId].totalSupply);
		if (allshares[_tokenId].maxTotalBalance > 0)
			if (allshares[_tokenId].balances[user] + value > allshares[_tokenId].maxTotalBalance)
				return false;
		
		allshares[_tokenId].balances[user] += value;
		allshares[_tokenId].ready += value;
		allshares[_tokenId].members[allshares[_tokenId].membersCount] = msg.sender;
		allshares[_tokenId].membersCount++;
		return true;
	}
	
	function getMembersCount(uint _tokenId) public view returns(uint) {
		return allshares[_tokenId].membersCount;
	}
	
	function getMember(uint _tokenId, uint ind) public view returns(address) {
		return allshares[_tokenId].members[ind];
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
	
	function acceptDividends(uint _tokenId) payable external {
		Share storage cur = allshares[_tokenId];
		uint forSingle = msg.value / cur.totalSupply;
		for (uint i = 0; i < cur.membersCount; i++) {
		    address this_member = cur.members[i];
		    uint this_coins = cur.balances[this_member] * forSingle;
		    if (this_coins > 0) {
		        this_member.transfer(this_coins);
		    }
		}
		
		uint back = msg.value - forSingle * cur.totalSupply;
		msg.sender.transfer(back);
		
		emit AcceptDividends(_tokenId, forSingle * cur.totalSupply);
	}
}