// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../h2oToken.sol";
import "../gremlinToken.sol";

contract GremlinNFTType2 is ERC721 {

    H2oToken public h2oToken;
    GremlinToken public gremlinToken;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => uint256[]) public addressNFTs;
    mapping(uint256 => uint) public nftIdType;

    uint256 public tokenPrice = 10000000000;
    
    address private admin;
    address private owner;
    address private presaleContractAddress;

    constructor(address _admin) ERC721("Gremlin NFT 2", "GN2") {
      owner = msg.sender;
      admin = _admin;
    }

 modifier onlyOwner { 
      require(
        msg.sender == admin ||
        msg.sender == owner , "Ownable: You are not the owner."
      );
      _;
    }

    function createNFT(address _addressTo, uint256 _nftAmount) public returns (uint[] memory nftIds) {

        if(msg.sender != admin) {
            uint256 h2oTokenBalance = h2oToken.balanceOf(_addressTo);
            uint256 gremlinTokenBalance = gremlinToken.balanceOf(_addressTo);

            require(h2oTokenBalance >= tokenPrice * 10**18 * _nftAmount, 'Your H2O balance is too low!');
            require(gremlinTokenBalance >= tokenPrice * 10**18 * _nftAmount, 'Your GREMLIN balance is too low!');

            h2oToken.burn(_addressTo, tokenPrice * 10**18 * _nftAmount);
            gremlinToken.burn(_addressTo, tokenPrice * 10**18 * _nftAmount);
        }

        uint[] memory mintedNftsId = new uint[](_nftAmount);

        for (uint i = 0; i < _nftAmount; i++) 
        {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(_addressTo, newItemId);

            addressNFTs[_addressTo].push(newItemId);
            mintedNftsId[i] = newItemId;
        }
      

      return(mintedNftsId);
    }

    function setGremlinAndH2oAddress(address _gremlinTokenAddress, address _h2oTokenAddress) onlyOwner public {
        gremlinToken = GremlinToken(_gremlinTokenAddress);
        h2oToken = H2oToken(_h2oTokenAddress);
    }

    function changeTokensAmountToMint(uint256 _tokensAmount) onlyOwner public returns(bool) {
      tokenPrice = _tokensAmount;
      return true;
    }

    function getNftType(uint256 _nftId) external view virtual returns(uint){
      return nftIdType[_nftId];
    }

    function getAddressNFTs(address _address) external view virtual returns(uint256[] memory){
      return addressNFTs[_address];
    }

    function withdraw(address payable _addressTo) onlyOwner public returns(uint256){
        _addressTo.transfer(address(this).balance);

        return address(this).balance;
    }

    function _burnToken(uint256 tokenId) public returns(uint256 _tokenId) {

      address tokenOwner = ownerOf(tokenId);

      for (uint i = 0; i < addressNFTs[tokenOwner].length; i++) 
      {
        if(addressNFTs[tokenOwner][i] == tokenId){
          delete addressNFTs[tokenOwner][i];
        }
      }

      _afterTokenTransfer(owner, address(0), tokenId, 1);

      return tokenId;
    }
}
