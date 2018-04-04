pragma solidity ^0.4.11;

import './Interfaces.sol';


import './RemoteWallet.sol';



contract DummyParent is RemoteWallet, util {
    
  uint256 created;
    
  //event DebugAddress(address _address);
  //event DebugString(string _string);
  //event DebugUInt(uint _value);
  //event DebugBytes4(bytes4 _signature);
    
  function DummyParent() RemoteWallet(address(this), msg.sender) {
      created = block.timestamp;
  }
    
  function Distribute(uint256 _start_time, bool _absolute, uint256 _days, uint256 _amount, uint256 _descending_amount, bytes32 _caption) external RestrictedCall() returns(uint256) {
    
  }
  
  function PostInit() external RestrictedCall() returns(address) {
      
  }
  
  function AddAngelInvestors() external RestrictedCall() returns(address) {
      
  }
  
  function _InitOwnerPermissions() internal {
    super._InitOwnerPermissions();
  }
  
  function _InitParentPermissions() internal {
    super._InitParentPermissions();
    
    //There is no parent
  }
 
  //Can still selfdestruct before distribution begins, after that contract becomes immortal.
  function ForceMajeure() external RestrictedCall() {
    
  }
  
  function Deposit() payable public {
   
  }
  
  function GetBurnedTokenAmount() public constant returns(uint256) {
    
  }
  
  function GetCreationDate() public constant returns(uint256) {
    
  }
  
  function SetSuperMajorityAddress(address _supermajority) external RestrictedCall() {
    
  }
  
  function SetBurnRequired(bool _required) public RestrictedCall() {
    
  }
  
  function RequireBurn() public constant returns(bool) {
    
  }
  
  function () RestrictedCall() payable {
    
  }
  
  function PlaceOrder(bytes8 _ref) RestrictedCall() payable public {
    
  }
  
  function GetReferralLink(address _address) public constant returns(bytes8) {
    
  }
  
  function FindOwnerByReferralLink(bytes8 _ref_link) public constant returns(address) {
    
  }
  
  
  function ProcessBuyOrder(uint256 _order_id) internal returns(uint256) {
    
  }
  
  function ClaimMyTokens(uint256 _max_orders) public returns(uint256) {
    
  }
  
  
  function ProcessTransaction(bytes8 _ref) internal returns(uint256) {
    
  }
  
  
  //Allow ICO participants to get full refund at any given time outside of distribution hours (won't work during ICO period)
  function GetRefund() public returns(uint256) {
    
  }
  
  function GetCurrentDistributionPeriod() public constant returns(uint256) {
    
  }
  
  function GetAmountInCirculation() public constant returns(uint256) {
    
  }
  
  
  function GetDistributionStruct1(uint256 _dist_period_id) external  constant returns(
        uint256 ether_gathered,
        uint256 tokens_released,
        uint256 tokens_total,
        bool ended,
        uint256 start_time,
        uint256 end_time,
        uint256 days_total)
  {
    
  }
  
  function GetDistributionStruct2(uint256 _dist_period_id) external constant returns(
        uint256 descending_amount,
        bytes32 caption,
        uint256 amount,
        uint256 daily_amount,
        uint256 ref_reserve_percentage,
        uint256 recent_daily_dist_id)
  {
    
  }
  
  function GetDailyDistributionStruct1(uint256 _dist_period_id, uint256 _daily_dist_id) external constant returns(
        uint256 day,
        uint256 start_time,
        uint256 end_time,
        uint256 daily_amount,
        uint256 ref_order_amount,
        uint256 amount_in_orders)
  {
    
  }
  
  function GetDailyDistributionStruct2(uint256 _dist_period_id, uint256 _daily_dist_id) external constant returns(
        uint256 ether_gathered,
        uint256 tokens_released,
        uint256 tokens_total,
        bool ended)
  {
    
  }
  
  function GetOrderStruct(uint256 _order_id) external constant returns(
        uint256 value,
        uint256 dist_period_id,
        uint256 daily_dist_id,
        uint256 received_tokens,
        bool processed,
        address owner,
        address ref,
        uint256 reference_value)
  {
    
  }
  
  
  
  function GetCurrentDailyDistributionDay(uint256 _dist_period_id) public constant returns(uint256) {
    
  }
  
  function GetFoundationTokenStorage() public constant returns(address) {
    
  }
  
  function HasTokenStorage(address _address) public constant returns(bool) {
    
  }
  
  function HasVirtualWallet(address _address) public constant returns(bool) {
    
  }

  function GetVirtualWallet(address _address) public constant returns(address) {
    
  }
  
  function HasColdStorage(address _address) public constant returns(bool) {
    
  }
  
  function GetColdStorage(address _address) public constant returns(address) {
    
  }
  
  function GetTokenStorage(address _address) public constant returns(address) {
    
  }
  
  function GetSuperMajorityWallet() public constant returns(address) {
    
  }
  
  function CreateColdStorage(address _address) internal returns(address) {
    
  }
  
  function CreateTokenStorage(uint256 _daily_amount) public returns(address) {
    
  }
  
  function CreateVirtualWallet(address _address) internal returns(address) {
    
  }
  
  
  function _TMP_GetPermissionByName(address _wallet, string func_signature, address _for) public constant returns(bool, bool) {
    
  }
  
  //TMP
  function GetBlockTimestamp() public constant returns(uint256) {
    
  }
  
  function _TMP_forward_time(uint256 _days) RestrictedCall() public returns(uint256) {
     
  }
  
  function _TMP_get_time_shift() public constant returns(uint256) {
    
  }
  
  
  //Callbacks
  //Callbacks, address _from = wallet (previous or current) owner, then we look up the existing wallets and check if msg.send matches any of them, then we know message is valid.
  function WalletOwnershipChanged(address _wallet, address _old_owner, address _to) external returns(bool) {
    
  }

  function WalletParentChanged(address _wallet, address _from, address _new_parent) external {
    
  }
  
  function WalletWithdrewCallback(address _from, address _to, uint256 _amount) external {
    
  }
  
  function RefundedNotification(address _from, uint256 _amount_burned, uint256 _amount_refunded)  external {
    
  }


}