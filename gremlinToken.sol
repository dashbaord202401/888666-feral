pragma solidity ^0.8.6;

import "./h2oToken.sol";
import "./nftContract.sol";
import './gremlinContract.sol';

contract GremlinToken {
    H2oToken public h2oToken;
    NFTContract public nftContract;
    GremlinContract public gremlinContract;

    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public allowance;


    string public name = 'Gremlin';
    string public symbol = 'GREMLIN';
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;

    address owner;

    address public nftContractAddress;
    address public h2oContractAddress;
    address public gremlinContractAddress;

    constructor(){
        owner = msg.sender;
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    modifier onlyOwner { 
      require(
        msg.sender == owner ||
        msg.sender == gremlinContractAddress || 
        msg.sender == nftContractAddress, "Ownable: You are not the owner."
      );
        _;
    }

    function setH2oAddress(address payable _h2oTokenAddress) public onlyOwner {
      h2oToken = H2oToken(_h2oTokenAddress);
      h2oContractAddress = _h2oTokenAddress;
    }

    function setGremlinContractAddress(address payable _gremlinContractAddress) public onlyOwner {
      gremlinContract = GremlinContract(_gremlinContractAddress);
      gremlinContractAddress = _gremlinContractAddress;
    }

    function setNftAddress(address payable _nftContractAddress) public onlyOwner {
      nftContract = NFTContract(_nftContractAddress);
      nftContractAddress = _nftContractAddress;
    }

    function _transferBurnH2oTokens(address _to) private {
      uint256 h2oTokenBalance = h2oToken.balanceOf(_to);
      if(h2oTokenBalance > 0){
        h2oToken.burn(_to, h2oTokenBalance);
      }
    }

    function balanceOf(address _address) public view returns(uint256) {
        return balances[_address];
    }

    function burn(address _to, uint256 _value) onlyOwner public returns(bool){
        require(_value > 0, 'Insufficient amount');
        balances[_to] -= _value;
        totalSupply -= _value;
        return true;
    }

    function mint(address _to, uint256 _value) onlyOwner public returns(bool) {
        require(_value > 0, 'Insufficient amount');
        balances[_to] += _value;
        totalSupply += _value;
        return true;
    }

    function transfer(address _to, uint256 _value ) public returns(bool) {
        require(balances[msg.sender] >= _value, 'Insufficient balance');
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        _transferBurnH2oTokens(msg.sender);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom( address _from ,address _to, uint256 _value ) public returns(bool) {
        require(balances[_from] >= _value, 'Insufficient balance');
        require(allowance[_from][msg.sender] >= _value, 'Insufficient allowance');
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns(bool) {
        require(balances[msg.sender] >= _value, 'Insufficient balance');
        require(_spender != msg.sender, 'You cannot make approve on yourself');
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}
