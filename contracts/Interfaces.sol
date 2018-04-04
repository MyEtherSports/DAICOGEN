pragma solidity ^0.4.11;

import './std.sol';
import './RemoteWalletHeaders.sol';

contract Types {

      struct Order {
        uint256 id;
        uint256 value;
        
        uint256 dist_period_id;
        uint256 daily_dist_id;
        
        uint256 received_tokens;
        bool processed;
        address owner;
        address ref;
        uint256 influence_value;
      }
      
      //Base dist object, mostly containing logging information for statistics.
      struct Dist {
        uint256 ether_gathered;
        uint256 tokens_released;
        uint256 tokens_total;
        bool ended;
      }
      
      //DailyDist extends Dist and has a short span (24 hours)
      struct DailyDist {
        Dist dist;
        
        uint256 id;
        uint256 day;
        uint256 start_time;
        uint256 end_time;
        uint256 daily_amount;
        
        uint256 ref_order_amount; //how much referrals have put in themselves
        uint256 amount_in_orders; //how much everyone has put in
        
        uint256[] order_ids;
        
        mapping ( address => uint256 ) find_order_id_by_address;
        mapping( address => uint256 ) total_amount_in_orders;
      }
      
      //DailyDist extends Dist and contains a large period of daily distributions (from 1 day to exact)
      struct DistPeriod {
        Dist dist;
        
        uint256 id;
        uint256 start_time;
        uint256 end_time;
        uint256 days_total;
        uint256 descending_amount;
        bytes32 caption;
        
        uint256 amount;
        uint256 daily_amount;
        uint256 ref_reserve_percentage;
        
        uint256 recent_daily_dist_id;
        DailyDist[] daily_dists;
        mapping(uint256 => uint256) find_daily_dist_id_by_day;
      }
  
    struct Tracker {
        uint256 tokens_issued;
        uint256 initial_supply;
        uint256 tokens_burned;
      }
  
      struct DataContainer {
        address owner;
        address parent;
        uint wallet_type;
        
          Tracker tracker;
          
          mapping(address => uint256) influence_value;
          mapping(address => address) fund_referral_by_address;
          mapping(address => address) find_owner_by_smart_wallet_address;
          
          address supermajority_group;
          address tokens_for_distribution;
          address foundation_virtual_wallet;
          address foundation_token_storage;
          
          uint256 distributed;
          
          DistPeriod[] dist_periods;
          Order[] orders;
          
          address[] virtual_wallets;
          address[] cold_storages;
          
          mapping(address => address) find_virtual_wallet;
          mapping(address => address) find_cold_storage;
          mapping(address => address) find_token_storage;
          
          uint256 _tmp_timeshift;
          uint256 locked_ether_amount;
          uint256 locked_token_amount;
          
          mapping(address => uint256[]) find_orders;
          
          address lib_user;
          bool burn_during_refund;
          
          mapping(bytes8 => address) find_referral_address;
      }
}


 contract MyEtherSportsTokenInterface {
   event Transfer(address indexed from, address indexed to, uint value);
   event Approval(address indexed owner, address indexed spender, uint value);

   function totalSupply() public constant returns (uint);
   function balanceOf(address who) public constant returns (uint);
   function allowance(address owner, address spender) public constant returns (uint);
   function transfer(address to, uint value) public returns (bool ok);
   function transferFrom(address from, address to, uint value) public returns (bool ok);
   function approve(address spender, uint value) public returns (bool ok);
 }

contract MasterContractInterface is RemoteWalletInterface, MyEtherSportsTokenInterface {

    //Since libraries can't derive from other contracts, events must be declared twice and have to match in order for them to get triggered.
    event NewDistributionPeriod(uint256 distribution_period_id);
    event BuyOrderCreated(uint256 _dist_period_id, uint256 _dist_day, uint256 _order_id, uint256 _order_value);
    event TokensBurned(uint256 amount);
    event RefundedNotificationEvent(address _from, uint256 _amount_burned, uint256 _amount_refunded);
    
    event WalletParentChangedEvent(address _wallet, address _from, address _new_parent);
    event WalletOwnershipChangedEvent(address _wallet, address _old_owner, address _to);
    
    event WalletWithdrewEvent(address _from, address _to, uint256 _amount);
    
  function _InitOwnerPermissions() internal;
  function Deposit() payable public;
  function PostInit() external returns(address);
  function AddAngelInvestors() external returns(address);
  function GetBurnedTokenAmount() public constant returns(uint256);
  function GetCreationDate() public constant returns(uint256);
  function SetSuperMajorityAddress(address _supermajority) external;
  function SetBurnRequired(bool _required) public;
  function RequireBurn() public constant returns(bool);
  function () payable;
  function PlaceOrder(bytes8 _ref) payable public;
  function ForceMajeure() external;
  function GetReferralLink(address _address) public constant returns(bytes8);
  function FindOwnerByReferralLink(bytes8 _ref_link) public constant returns(address);
  function ProcessBuyOrder(uint256 _order_id) internal returns(uint256);
  function ClaimMyTokens(uint256 _max_orders) public returns(uint256);
  function ProcessTransaction(bytes8 _ref) internal returns(uint256);
  function GetRefund() public returns(uint256);
  function GetCurrentDistributionPeriod() public constant returns(uint256);
  function GetAmountInCirculation() public constant returns(uint256);
  function GetCurrentDailyDistributionDay(uint256 _dist_period_id) public constant returns(uint256);
  function GetFoundationTokenStorage() public constant returns(address);
  function Distribute(uint256 _start_time, bool _absolute, uint256 _days, uint256 _amount, uint256 _descending_amount, bytes32 _caption) external returns(uint256);
  function HasTokenStorage(address _address) public constant returns(bool);
  function HasVirtualWallet(address _address) public constant returns(bool);
  function GetVirtualWallet(address _address) public constant returns(address);
  function HasColdStorage(address _address) public constant returns(bool);
  function GetColdStorage(address _address) public constant returns(address);
  function GetTokenStorage(address _address) public constant returns(address);
  function GetSuperMajorityWallet() public constant returns(address);
  function CreateColdStorage(address _address) internal returns(address);
  function CreateTokenStorage(uint256 _daily_amount) public returns(address);
  function CreateVirtualWallet(address _address) internal returns(address);
  
  function _TMP_GetPermissionByName(address _wallet, string func_signature, address _for) public constant returns(bool, bool);
  function _TMP_get_time_shift() public constant returns(uint256);
  //function _TMP_forward_time(uint256 _days) public returns(uint256);
  
  //Callbacks
  function WalletOwnershipChanged(address _wallet, address _from, address _to) external returns(bool);
  function WalletParentChanged(address _wallet, address _from, address _new_parent) external;
  function WalletWithdrewCallback(address _from, address _to, uint256 _amount) external;
  function RefundedNotification(address _from, uint256 _amount_burned, uint256 _amount_refunded) external;

  function GetDistributionStruct1(uint256 _dist_period_id) external constant returns(
        uint256 ether_gathered,
        uint256 tokens_released,
        uint256 tokens_total,
        bool ended,
        uint256 start_time,
        uint256 end_time,
        uint256 days_total);
  
  function GetDistributionStruct2(uint256 _dist_period_id) external constant returns(
        uint256 descending_amount,
        bytes32 caption,
        uint256 amount,
        uint256 daily_amount,
        uint256 ref_reserve_percentage,
        uint256 recent_daily_dist_id);
        
  function GetDailyDistributionStruct1(uint256 _dist_period_id, uint256 _daily_dist_id) external constant returns(
        uint256 day,
        uint256 start_time,
        uint256 end_time,
        uint256 daily_amount,
        uint256 ref_order_amount,
        uint256 amount_in_orders);
        
  function GetDailyDistributionStruct2(uint256 _dist_period_id, uint256 _daily_dist_id) external constant returns(
        uint256 ether_gathered,
        uint256 tokens_released,
        uint256 tokens_total,
        bool ended);
        
  function GetOrderStruct(uint256 _order_id) external constant returns(
        uint256 value,
        uint256 dist_period_id,
        uint256 daily_dist_id,
        uint256 received_tokens,
        bool processed,
        address owner,
        address ref,
        uint256 influence_value);
}