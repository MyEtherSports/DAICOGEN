pragma solidity ^0.4.11;

import './Interfaces.sol';
import './SafeMathLib.sol';
import './MyEtherSportsToken.sol';

import './BaseLib.sol';
import './BaseLib2.sol';
import './BaseLib3.sol';
import './CoreLib2.sol';
import './CoreLib3.sol';

import './RemoteWallet.sol';



contract MyEtherSports is MasterContractInterface, RemoteWallet, MyEtherSportsToken, util {
  using SafeMathLib for uint256;
    
  uint256 created;
    
  //event DebugAddress(address _address);
  //event DebugString(string _string);
  //event DebugUInt(uint _value);
  //event DebugBytes4(bytes4 _signature);
    
  uint256 foundation_amount;
  uint256 angel_investors_amount;
  uint256 distribution_amount;

  Types.DataContainer container;
  
  
  modifier AllowRemoteWalletCall(address _address) {
    if ((HasTokenStorage(_address) && GetTokenStorage(_address) == msg.sender) || (HasVirtualWallet(_address) && GetVirtualWallet(_address) == msg.sender) || (HasColdStorage(_address) && GetColdStorage(_address) == msg.sender)) _;
  }
  
  
  modifier IsValidDistributionID(uint256 _dist_id) {
    require(_dist_id > 0 && _dist_id <= container.dist_periods.length);
    if (true) {
      _;
    }
  }
  
  modifier IsValidOrderID(uint256 _order_id) {
    require(_order_id > 0 && _order_id <= container.orders.length);
    if (true) {
      _;
    }
  }
  
  modifier IsValidDailyDistributionID(uint256 _dist_id, uint256 _daily_dist_id) {
    require(_dist_id > 0 && _dist_id <= container.dist_periods.length);
    Types.DistPeriod storage current_dist_period = container.dist_periods[_dist_id-1];
    require(_daily_dist_id > 0 && _daily_dist_id <= current_dist_period.daily_dists.length);
    if (true) {
      _;
    }
  }

  function MyEtherSports() MyEtherSportsToken(address(this)) RemoteWallet(address(this), msg.sender) {
      created = block.timestamp;
        
      foundation_amount = INITIAL_SUPPLY * 8 / 100; //8%
      angel_investors_amount = INITIAL_SUPPLY * 2 / 100;  //2%
      distribution_amount = INITIAL_SUPPLY - foundation_amount - angel_investors_amount; //90%
  }
    
  function Distribute(uint256 _start_time, bool _absolute, uint256 _days, uint256 _amount, uint256 _descending_amount, bytes32 _caption) external RestrictedCall() returns(uint256) {
    return BaseLib2.Distribute(container, _absolute, _start_time, _days, _amount, _descending_amount, _caption);
  }
  
  function PostInit() external RestrictedCall() returns(address) {
      return BaseLib3.PostInit(container, data, token, INITIAL_SUPPLY, foundation_amount, distribution_amount);
  }
  
  function AddAngelInvestors() external RestrictedCall() returns(address) {
      return BaseLib3.AddAngelInvestors(container, data, token, angel_investors_amount);
  }
  
  function _InitOwnerPermissions() internal {
    super._InitOwnerPermissions();
    
    BaseLib._InitOwnerPermissions(data);
  }
  
  function _InitParentPermissions() internal {
    super._InitParentPermissions();
    
    //There is no parent
  }
 
  //Can still selfdestruct before distribution begins, after that contract becomes immortal.
  function ForceMajeure() external RestrictedCall() {
    require(container.dist_periods.length > 0 && block.timestamp.add(container._tmp_timeshift) < container.dist_periods[0].start_time);
    selfdestruct(container.owner);
  }
  
  function Deposit() payable public {
    return BaseLib.Deposit(container);
  }
  
  function GetBurnedTokenAmount() public constant returns(uint256) {
    return balanceOf(address(0x0));
  }
  
  function GetCreationDate() public constant returns(uint256) {
    return created;
  }
  
  function SetSuperMajorityAddress(address _supermajority) external RestrictedCall() {
    if (msg.sender == data.owner) require(container.supermajority_group == address(0x0)); //Only once
    BaseLib2.SetSuperMajorityAddress(container, data, _supermajority);
  }
  
  function SetBurnRequired(bool _required) public RestrictedCall() {
    require(_required == false); //Once it's set it can't be undone
    container.burn_during_refund = _required;
  }
  
  function RequireBurn() public constant returns(bool) {
    return container.burn_during_refund;
  }
  
  function () RestrictedCall() payable {
    //DebugUInt(address(this).balance);
    //DebugUInt(msg.value);
    ProcessTransaction(bytes8(sha256(address(0x0)))); //No referral
  }
  
  function PlaceOrder(bytes8 _ref) RestrictedCall() payable public {
    //DebugUInt(address(this).balance);
    //DebugUInt(msg.value);
    ProcessTransaction(_ref);
  }
  
  function GetReferralLink(address _address) public constant returns(bytes8) {
    return bytes8(sha256(_address));
  }
  
  function FindOwnerByReferralLink(bytes8 _ref_link) public constant returns(address) {
    return container.find_referral_address[_ref_link];
  }
  
  
  function ProcessBuyOrder(uint256 _order_id) internal returns(uint256) {
    return BaseLib2.ProcessBuyOrder(container, _order_id);
  }
  
  function ClaimMyTokens(uint256 _max_orders) public returns(uint256) {
    return BaseLib2.ClaimMyTokens(container, _max_orders);
  }
  
  
  function ProcessTransaction(bytes8 _ref) internal returns(uint256) {
    //DebugString("PreProcessTransaction");
    //DebugAddress(msg.sender);
    return BaseLib2.ProcessTransaction(container, data, _ref);
  }
  
  
  //Allow ICO participants to get full refund at any given time outside of distribution hours (won't work during ICO period)
  function GetRefund() public returns(uint256) {
    var (cold_storage, tokens_to_burn) = BaseLib.GetRefund(container);
    require(tokens_to_burn > 0);
    //Send necessary token amount to cold storage wallet to get a refund
    require( approve(msg.sender, tokens_to_burn) );
    require( transferFrom(msg.sender, cold_storage, tokens_to_burn) );
    
    return ColdStorageInterface(cold_storage).APIGetRefund();
  }
  
  function GetCurrentDistributionPeriod() public constant returns(uint256) {
    return BaseLib2.GetCurrentDistributionPeriod(container);
  }
  
  function GetAmountInCirculation() public constant returns(uint256) {
    return INITIAL_SUPPLY - balanceOf(this) - balanceOf(address(0x0));// - container.locked_token_amount;
  }
  
  
  function GetDistributionStruct1(uint256 _dist_period_id) external IsValidDistributionID(_dist_period_id) constant returns(
        uint256 ether_gathered,
        uint256 tokens_released,
        uint256 tokens_total,
        bool ended,
        uint256 start_time,
        uint256 end_time,
        uint256 days_total)
  {
    return BaseLib2.GetDistributionStruct1(container, _dist_period_id);
  }
  
  function GetDistributionStruct2(uint256 _dist_period_id) external IsValidDistributionID(_dist_period_id) constant returns(
        uint256 descending_amount,
        bytes32 caption,
        uint256 amount,
        uint256 daily_amount,
        uint256 ref_reserve_percentage,
        uint256 recent_daily_dist_id)
  {
    return BaseLib2.GetDistributionStruct2(container, _dist_period_id);
  }
  
  function GetDailyDistributionStruct1(uint256 _dist_period_id, uint256 _daily_dist_id) external IsValidDailyDistributionID(_dist_period_id, _daily_dist_id) constant returns(
        uint256 day,
        uint256 start_time,
        uint256 end_time,
        uint256 daily_amount,
        uint256 ref_order_amount,
        uint256 amount_in_orders)
  {
    return BaseLib2.GetDailyDistributionStruct1(container, _dist_period_id, _daily_dist_id);
  }
  
  function GetDailyDistributionStruct2(uint256 _dist_period_id, uint256 _daily_dist_id) external IsValidDailyDistributionID(_dist_period_id, _daily_dist_id) constant returns(
        uint256 ether_gathered,
        uint256 tokens_released,
        uint256 tokens_total,
        bool ended)
  {
    return BaseLib2.GetDailyDistributionStruct2(container, _dist_period_id, _daily_dist_id);
  }
  
  function GetOrderStruct(uint256 _order_id) external IsValidOrderID(_order_id) constant returns(
        uint256 value,
        uint256 dist_period_id,
        uint256 daily_dist_id,
        uint256 received_tokens,
        bool processed,
        address owner,
        address ref,
        uint256 reference_value)
  {
    return BaseLib2.GetOrderStruct(container, _order_id);
  }
  
  
  
  function GetCurrentDailyDistributionDay(uint256 _dist_period_id) public constant returns(uint256) {
    return BaseLib2.GetCurrentDailyDistributionDay(container, _dist_period_id);
  }
  
  function GetFoundationTokenStorage() public constant returns(address) {
    return CoreLib2.GetFoundationTokenStorage(container);
  }
  
  function HasTokenStorage(address _address) public constant returns(bool) {
    return CoreLib2.HasTokenStorage(container, _address);
  }
  
  function HasVirtualWallet(address _address) public constant returns(bool) {
    return CoreLib2.HasVirtualWallet(container, _address);
  }

  function GetVirtualWallet(address _address) public constant returns(address) {
    return CoreLib2.GetVirtualWallet(container, _address);
  }
  
  function HasColdStorage(address _address) public constant returns(bool) {
    return CoreLib2.HasColdStorage(container, _address);
  }
  
  function GetColdStorage(address _address) public constant returns(address) {
    return CoreLib2.GetColdStorage(container, _address);
  }
  
  function GetTokenStorage(address _address) public constant returns(address) {
    return CoreLib2.GetTokenStorage(container,_address);
  }
  
  function GetSuperMajorityWallet() public constant returns(address) {
    return CoreLib2.GetSuperMajorityWallet(container);
  }
  
  function CreateColdStorage(address _address) internal returns(address) {
    return CoreLib3.CreateColdStorage(container, _address);
  }
  
  function CreateTokenStorage(uint256 _daily_amount) public returns(address) {
    return CoreLib2.CreateTokenStorage(container, _daily_amount);
  }
  
  function CreateVirtualWallet(address _address) internal returns(address) {
    return CoreLib.CreateVirtualWallet(container, _address);
  }
  
  
  function _TMP_GetPermissionByName(address _wallet, string func_signature, address _for) public constant returns(bool, bool) {
    RemoteWalletInterface remote_wallet = RemoteWalletInterface(_wallet);
    return remote_wallet.APIGetPermissionBySig(bytes4(sha3(func_signature)), _for);
  }
  
  /* TMP
  function GetBlockTimestamp() public constant returns(uint256) {
    return block.timestamp.add(container._tmp_timeshift);
  }
  */
  
  /* TMP
  function _TMP_forward_time(uint256 _days) RestrictedCall() public returns(uint256) {
     container._tmp_timeshift += _days.mul(RemoteWalletLib.GetSecondsInADay());
  }
  */
  
  function _TMP_get_time_shift() public constant returns(uint256) {
    return container._tmp_timeshift;
  }
  
  
  //Callbacks, address _from = wallet (previous or current) owner, then we look up the existing wallets and check if msg.send matches any of them, then we know message is valid.
  function WalletOwnershipChanged(address _wallet, address _old_owner, address _to) AllowRemoteWalletCall(_old_owner) external returns(bool) {
    require(CoreLib.WalletOwnershipChanged(container, data, _wallet, _old_owner, _to)); //Confirm change
    return true;
  }

  function WalletParentChanged(address _wallet, address _from, address _new_parent) AllowRemoteWalletCall(_from) external {
    return CoreLib2.WalletParentChanged(container, _wallet, _from, _new_parent);
  }
  
  function WalletWithdrewCallback(address _from, address _to, uint256 _amount) AllowRemoteWalletCall(_from) external {
    return CoreLib2.WalletWithdrewCallback(container, _from, _to, _amount);
  }
  
  function RefundedNotification(address _from, uint256 _amount_burned, uint256 _amount_refunded) AllowRemoteWalletCall(_from) external {
    return CoreLib2.RefundedNotification(container, _from, _amount_burned, _amount_refunded);
  }


}