pragma solidity ^0.8.6;

import "./gremlinToken.sol";
import "./h2oToken.sol";
import "./libraries/safeMath.sol";
import "./nftContracts/nft1.sol";

contract GremlinContract {
  using SafeMath for uint256;

   H2oToken public h2oToken;
   GremlinToken public gremlinToken;
   GremlinNFTType1 public gremlinNFTType1;


   uint256 public day = 60 * 60 * 24;
   uint256 public boostPrice = 0.025 * 10**18;
   uint256 public bnbBalance = 0;
   uint256 public gremlinCurrency = 10000000000;

   uint256 public availableGremlinsToBuy = 150000000000 * 10**18;

   mapping(address => address) public addressReferrals;

   mapping(address => uint256) public addressH2oCooldown;
   mapping(address => uint256) public addressBoostQuantity;
   mapping(uint256 => mapping(uint => uint256)) public tokensClaimCooldown;

   mapping(address => uint256) public referralBuyAmount;
   mapping(address => uint256) public withdrawnBuyAmount;

   mapping(address => uint256) public referralGremlinProfitAmount;
   mapping(address => uint256) public withdrawnGremlinProfitAmount;

   mapping(address => uint256) public referralH2oProfitAmount;
   mapping(address => uint256) public withdrawnH2oProfitAmount;

   mapping(address => uint256) public totalNftRewardGremlin;
   mapping(address => uint256) public totalNftRewardH2o;

   mapping(address => mapping(uint => uint256)) public addressReferralsByLevel;

   mapping(address => mapping(uint => uint256)) public addressBuyRefferalsByLevel;
   mapping(address => mapping(uint => uint256)) public addressEarnReferralsByLevel;

   address public defaultReferrer;

   uint[5] public buyReferralPercent = [
     7,
     5,
     3,
     3,
     2
   ];

   uint[7] public earnReferralPercent = [
     20,
     15,
     12,
     10,
     7,
     4,
     2
   ];

    uint[6] public dailyNftReward = [
      150000000,
      300000000,
      750000000,
      1500000000,
      3000000000,
      15000000000
    ];
    
    address private owner;

    address public nftContractAddress;
    address public h2oContractAddress;
    address public gremlinContractAddress;

    constructor(
      address _gremlinTokenAddress, 
      address _h2oTokenAddress, 
      address[] memory _nftContractAddresses, 
      address _defaultReferrer
    ){
      owner = msg.sender;

      gremlinToken = GremlinToken(_gremlinTokenAddress);

      h2oToken = H2oToken(_h2oTokenAddress);

      gremlinNFTType1 = GremlinNFTType1(_nftContractAddresses[0]);

      defaultReferrer = _defaultReferrer;
    }

    modifier onlyOwner {
      require(
        msg.sender == owner , "Ownable: You are not the owner."
      );
        _;
    }

    event GetBoost(address indexed _to);
    event GetH2o(address indexed _to, uint256 _amount);
    event ClaimReferralBuy(address indexed _to, uint256 _amount);
    event ClaimReferralProfit(address indexed _to, uint256 _gremlinAmount, uint256 _h2oAmount);
    event SetUpliner(address indexed _referral, address indexed _upliner);
    event ChangedGremlinCurrency(uint256 _price);
    event ClaimNftReward(address indexed _to, uint256 _gremlinAmount, uint256 _h2oAmount);
    event BuyGremlins(address _to, uint256 _amount);

    function getBoost() payable public returns(string memory){
      require(msg.value == boostPrice, 'Not enough BNB was sent');
      require(block.timestamp > addressBoostQuantity[msg.sender], 'You already have active boost');

      addressBoostQuantity[msg.sender] = 5;
      bnbBalance += msg.value;
      emit GetBoost(msg.sender);
      return 'You successfuly bought boost. It will last for 5 claims';
    }

    function referralBuyRewardUpliner(address _currentAddress, uint _currentDepth, uint256 _boughtAmount) private {
      address currentUpliner = addressReferrals[_currentAddress];
      if (_currentAddress == defaultReferrer || currentUpliner == address(0)) return;

      referralBuyAmount[currentUpliner] = _boughtAmount * buyReferralPercent[_currentDepth] / 100;

      if(_currentDepth == 5) return;

      referralBuyRewardUpliner(currentUpliner, _currentDepth++, _boughtAmount);
    }

    function referralEarnRewardUpliner(address _currentAddress, uint _currentDepth, uint256 _gremlinProfitAmount, uint256 _h2oProfitAmount) private {
      address currentUpliner = addressReferrals[_currentAddress];
      if (_currentAddress == defaultReferrer || currentUpliner == address(0)) return;

      if(_gremlinProfitAmount != 0){
        referralGremlinProfitAmount[currentUpliner] = _gremlinProfitAmount * earnReferralPercent[_currentDepth] / 100;
      }

      if(_h2oProfitAmount != 0){
        referralH2oProfitAmount[currentUpliner] = _h2oProfitAmount * earnReferralPercent[_currentDepth] / 100;
      }

      if(_currentDepth == 7) return;

      referralEarnRewardUpliner(currentUpliner, _currentDepth++, _gremlinProfitAmount, _h2oProfitAmount);
    }

    function buyGremlins(uint256 _bnbAmount ) public returns(uint256){
      require( addressReferrals[msg.sender] != address(0),'You dont have upliner!');

      uint256 gremlinsToMint = _bnbAmount.div(gremlinCurrency);

      require(gremlinsToMint <= availableGremlinsToBuy, 'Not enough available GREMLINS to buy!');

      availableGremlinsToBuy -= gremlinsToMint;

      gremlinToken.transfer(msg.sender, gremlinsToMint);

      referralBuyRewardUpliner(msg.sender, 0, gremlinsToMint);

      emit BuyGremlins(msg.sender, gremlinsToMint);
      return gremlinsToMint;
    }

    function getH2o() public returns(uint256){

      require( addressReferrals[msg.sender] != address(0),'You dont have upliner!');
      require((block.timestamp - addressH2oCooldown[msg.sender]) > day, 'H2O claim is in cooldown!');

      uint256 gremlinTokenBalance = gremlinToken.balanceOf(msg.sender);
      uint256 multiplier = addressBoostQuantity[msg.sender] != 0 ? 5 : 10;
      if(block.timestamp - addressH2oCooldown[msg.sender]  > day){
        h2oToken.mint(msg.sender, gremlinTokenBalance.div(multiplier));
        addressH2oCooldown[msg.sender] = block.timestamp;
        if(addressBoostQuantity[msg.sender] != 0){
          addressBoostQuantity[msg.sender] -= 1;
        }
      }

      emit GetH2o(msg.sender, gremlinTokenBalance.div(multiplier));
      return gremlinTokenBalance.div(multiplier);
    }

    function claimNft1Reward() public returns(uint256 amount) {
      uint256[] memory userNFTsArray = gremlinNFTType1.getAddressNFTs(msg.sender);

      uint gremlinAmountMint = 0;
      uint h2oAmountMint = 0;
      for( uint i = 0; i < userNFTsArray.length; i++ ){

        uint currentNftId = userNFTsArray[i];
        if(currentNftId != 0){
          uint currentNftType = 0;
          if(block.timestamp - tokensClaimCooldown[0][currentNftId] >= day){
            gremlinAmountMint += dailyNftReward[currentNftType];
            if(currentNftType == 5){
              h2oAmountMint += dailyNftReward[currentNftType];
            }
            tokensClaimCooldown[0][currentNftId] = block.timestamp;
          }
        }
      }

      if(gremlinAmountMint > 0){
        gremlinToken.mint(msg.sender, gremlinAmountMint * 10**18);
      }
      if(h2oAmountMint > 0) {
        h2oToken.mint(msg.sender, h2oAmountMint * 10**18);
      }
      referralEarnRewardUpliner(msg.sender, 0, gremlinAmountMint * 10**18, h2oAmountMint * 10**18);
      emit ClaimNftReward(msg.sender, gremlinAmountMint * 10**18, h2oAmountMint * 10**18);

      totalNftRewardGremlin[msg.sender] = gremlinAmountMint * 10**18;
      totalNftRewardH2o[msg.sender] = h2oAmountMint * 10**18;

      return gremlinAmountMint;
    }

    // function claimNFTsRewards() private returns(bool){

    //   require(addressReferrals[msg.sender] != address(0),'You dont have upliner!');
    //   uint gremlinAmountMint = 0;
    //   uint h2oAmountMint = 0;

    //   uint256[] memory userNFTsArray = nftContract.getAddressNFTs(msg.sender);

    //   for( uint i = 0; i < userNFTsArray.length; i++ ){
    //     uint currentNftId = userNFTsArray[i];
    //     uint currentNftType = nftContract.getNftType(currentNftId);
    //     if(block.timestamp - tokensClaimCooldown[currentNftId] >= day){
    //       gremlinAmountMint += dailyNftReward[currentNftType];
    //       if(currentNftType == 5){
    //         h2oAmountMint += dailyNftReward[currentNftType];
    //       }
    //       tokensClaimCooldown[currentNftId] = block.timestamp;
    //     }
    //   }
    //   if(gremlinAmountMint > 0){
    //     gremlinToken.mint(msg.sender, gremlinAmountMint * 10**18);
    //   }
    //   if(h2oAmountMint > 0) {
    //     h2oToken.mint(msg.sender, h2oAmountMint * 10**18);
    //   }
    //   referralEarnRewardUpliner(msg.sender, 0, gremlinAmountMint * 10**18, h2oAmountMint * 10**18);
    //   emit ClaimNftReward(msg.sender, gremlinAmountMint * 10**18, h2oAmountMint * 10**18);

    //   totalNftRewardGremlin[msg.sender] = gremlinAmountMint * 10**18;
    //   totalNftRewardH2o[msg.sender] = h2oAmountMint * 10**18;

    //   return true;
    // }

    function changeGremlinCurrency(uint256 _newCurrency) onlyOwner public returns(uint256){
      gremlinCurrency = _newCurrency;
      emit ChangedGremlinCurrency(_newCurrency);
      return _newCurrency;
    }

    //function updateUplinersCounter(address _upliner, uint _depth) private {

      //address _newUpliner = addressReferrals[_upliner];
      //addressReferralsByLevel[_upliner][_depth] += 1;
      //addressReferrals[msg.sender] = _upliner;

      //if(_newUpliner == address(0)) return; 
      //if(_newUpliner == defaultReferrer) return; 
      //if(_depth == 7) return;

      //updateUplinersCounter(_newUpliner, _depth++);
    //}

    function setUpliner(address _upliner) public returns(address){
        require(addressReferrals[msg.sender] == address(0), 'You already have upliner!');

        addressReferrals[msg.sender] = _upliner;
        emit SetUpliner(msg.sender, _upliner);
        return _upliner;
    }

    // function setNftContractAddresses(address[] _addresses) public returns(bool){

    // }

    function withdraw(address _to) payable public onlyOwner returns(uint256){
      payable(_to).transfer(bnbBalance);
      bnbBalance = 0;

      return bnbBalance;
    }

    function claimReferralBuyReward() public returns(uint256){
      require(referralBuyAmount[msg.sender] - withdrawnBuyAmount[msg.sender] > 0 , 'You have nothing to withdraw.');
      gremlinToken.mint(msg.sender, referralBuyAmount[msg.sender] - withdrawnBuyAmount[msg.sender]);

      withdrawnBuyAmount[msg.sender] = referralBuyAmount[msg.sender];

      emit ClaimReferralBuy(msg.sender, referralBuyAmount[msg.sender] - withdrawnBuyAmount[msg.sender]);
      return referralBuyAmount[msg.sender] - withdrawnBuyAmount[msg.sender];
    }

    function claimReferralProfitReward() public returns(uint256[2] memory){
      require(referralGremlinProfitAmount[msg.sender] - withdrawnGremlinProfitAmount[msg.sender] > 0 , 'You have nothing to withdraw.');

      gremlinToken.mint(msg.sender, referralGremlinProfitAmount[msg.sender] - withdrawnGremlinProfitAmount[msg.sender]);
      withdrawnGremlinProfitAmount[msg.sender] = referralGremlinProfitAmount[msg.sender];

      if(referralH2oProfitAmount[msg.sender] - withdrawnH2oProfitAmount[msg.sender] > 0){
        gremlinToken.mint(msg.sender, referralH2oProfitAmount[msg.sender] - withdrawnH2oProfitAmount[msg.sender]);
        withdrawnH2oProfitAmount[msg.sender] = referralH2oProfitAmount[msg.sender];
      }
      emit ClaimReferralProfit(
        msg.sender, 
        referralGremlinProfitAmount[msg.sender] - withdrawnGremlinProfitAmount[msg.sender], 
        referralH2oProfitAmount[msg.sender] - withdrawnH2oProfitAmount[msg.sender]
      );
      return [withdrawnGremlinProfitAmount[msg.sender], withdrawnH2oProfitAmount[msg.sender]];
    }

    //write logic of depositting tokens for availableGremlinsToBuy
}
