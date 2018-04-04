pragma solidity ^0.4.11;


import './Interfaces.sol';
import './SafeMathLib.sol';

import './CoreLib.sol';
import './CoreLib2.sol';
import './CoreLib3.sol';


library BaseLib2 {
  using SafeMathLib for uint256;
      
  event NewDistributionPeriod(uint256 distribution_period_id);
  event BuyOrderCreated(uint256 _dist_period_id, uint256 _dist_day, uint256 _order_id, uint256 _order_value);
  
  //event DebugAddress(address _address);
  //event DebugString(string _string);
  //event DebugUInt(uint _value);
  
  function ProcessTransaction(Types.DataContainer storage self, RemoteWalletLib.RemoteWalletData storage data, bytes8 _ref_hash) returns(uint256) {
    //DebugString("ProcessTransaction");
    //DebugAddress(msg.sender);
    require(msg.value > 0);
    require(msg.value >= 1 ether / 1000); //0.001 ether minimum
    
    address _ref = self.find_referral_address[_ref_hash];
    require(_ref != msg.sender);
    
    if (!CoreLib2.HasVirtualWallet(self, msg.sender)) CoreLib.CreateVirtualWallet(self, msg.sender);
    
    uint256 current_dist_period_id = GetCurrentDistributionPeriod(self);
    //DebugString("Process");
    //DebugUInt(current_dist_period_id);
    
    require(current_dist_period_id > 0 && current_dist_period_id <= self.dist_periods.length);
    
    Types.DistPeriod storage current_dist_period = self.dist_periods[current_dist_period_id-1];
    require (block.timestamp.add(self._tmp_timeshift) < current_dist_period.end_time);
    
    uint256 current_daily_dist_id = FindCurrentDailyDistributionID(self, current_dist_period);
    
    Types.DailyDist storage current_daily_dist = current_dist_period.daily_dists[current_daily_dist_id-1];
    
    current_dist_period.dist.ether_gathered = current_dist_period.dist.ether_gathered.add(msg.value);
    current_daily_dist.dist.ether_gathered = current_daily_dist.dist.ether_gathered.add(msg.value);
    
    
    uint256 new_order_id = _CreateBuyOrder(self, data, current_dist_period, current_daily_dist, _ref);

    return new_order_id;
  }
  
  function _ClaimTokensFor(Types.DataContainer storage self, address _address, uint256 _max_orders) returns(uint256) {
    uint256 tokens_collected = 0;
    //DebugString("ClaimMyTokens");
    //DebugAddress(_address);
    uint256 order_count = self.find_orders[_address].length;
    //DebugUInt(order_count);
    
    if (_max_orders == 0) _max_orders = order_count;
    
    for (uint256 i = 0; i < min(_max_orders, order_count); i++) {
      //DebugUInt(i);
      uint256 order_id = self.find_orders[_address][i];
      Types.Order storage order = self.orders[order_id-1];
      
      if (!order.processed) {
        tokens_collected = tokens_collected.add(ProcessBuyOrder(self, order_id));
        //DebugString("Back to loop");
        //DebugUInt(self.find_orders[_address].length);
        if (order.processed) {
          uint256 last_order = self.find_orders[_address][order_count-1];
          self.find_orders[_address][i] = last_order;
          self.find_orders[_address].length--; //Now we can safely lower array size
        }
        //DebugString("end iteration");
      }
    }
    
    return tokens_collected;
  }
  
  function ClaimMyTokens(Types.DataContainer storage self, uint256 _max_orders) returns(uint256) {
    return _ClaimTokensFor(self, msg.sender, _max_orders);
  }
  
  function ProcessBuyOrder(Types.DataContainer storage self, uint256 _order_id) returns(uint256) {
    //DebugString("Entering ProcessBuyOrder");
    require(_order_id > 0 && _order_id <= self.orders.length);
    Types.Order storage order = self.orders[_order_id-1];
    return _ProcessBuyOrder(self, order);
  }
  

  function _ProcessBuyOrder(Types.DataContainer storage self,Types.Order storage order) returns(uint256) {
   //DebugString("_ProcessBuyOrder end");
   Types.DistPeriod storage dist_period = self.dist_periods[order.dist_period_id-1];
   Types.DailyDist storage daily_dist = dist_period.daily_dists[order.daily_dist_id-1];
    
    uint256 current_dist_period_id = GetCurrentDistributionPeriod(self);
   
    if (order.dist_period_id == current_dist_period_id && order.daily_dist_id == GetCurrentDailyDistributionDay(self, current_dist_period_id)) {
      return 0; //Daily distribution is not over yet.
    }
    
    require(!order.processed);
    
    //DebugString("_ProcessBuyOrder passed");
    
    uint256 daily_ref_amount = min(daily_dist.daily_amount * daily_dist.ref_order_amount / daily_dist.dist.ether_gathered, daily_dist.daily_amount * (dist_period.ref_reserve_percentage) / 100);
    uint256 daily_amount = daily_dist.daily_amount - daily_ref_amount;
    
    uint256 tokens_issued = (daily_amount * order.value) / daily_dist.dist.ether_gathered;
    uint256 ref_tokens_issued = (daily_ref_amount * order.value) / daily_dist.dist.ether_gathered;

    //DebugUInt(tokens_issued);
    
    
    require(tokens_issued == TokenStorageInterface(self.tokens_for_distribution).APIWithdrawTo(tokens_issued, order.owner));
    
    if (!CoreLib2.HasColdStorage(self, order.owner)) CoreLib3.CreateColdStorage(self, order.owner);
    ColdStorageInterface cold_storage = ColdStorageInterface(CoreLib2.GetColdStorage(self, order.owner));
    
    tokens_issued += RewardReferral(self, dist_period, daily_dist, order, ref_tokens_issued);
    
    cold_storage._APIAddRefundableTokenAmount(tokens_issued);
    
    order.processed = true;

    return tokens_issued;
  }
  
  function RewardReferral(Types.DataContainer storage self,Types.DistPeriod storage dist_period,Types.DailyDist storage daily_dist,Types.Order storage order, uint256 ref_tokens_issued) returns(uint256) {
    uint256 referral_amount = ref_tokens_issued * order.influence_value / (order.influence_value + order.value);
    uint256 referee_amount = ref_tokens_issued * order.value / (order.influence_value + order.value);

    if(order.ref != address(0x0)) require(referral_amount == TokenStorageInterface(self.tokens_for_distribution).APIWithdrawTo(referral_amount, order.ref));
    else referee_amount += referral_amount;
    
    require(referee_amount == TokenStorageInterface(self.tokens_for_distribution).APIWithdrawTo(referee_amount, order.owner));

    self.influence_value[order.ref] = order.influence_value.add(order.value * order.influence_value / (order.influence_value + order.value) ); //Increase value
    return referee_amount;
  }
  
  function _CreateBuyOrder(Types.DataContainer storage self, RemoteWalletLib.RemoteWalletData storage data, Types.DistPeriod storage dist_period,Types.DailyDist storage daily_dist, address _ref) returns(uint256) {
    //Search for already existing buy order
    uint256 existing_order_id = daily_dist.find_order_id_by_address[msg.sender];
    
    
    //DebugUInt(existing_order_id);
    if (existing_order_id == 0) {
      //DebugString("Creating new order");
      self.orders.length++;
      uint256 new_order_id = self.orders.length;
      
      Types.Order storage new_order = self.orders[new_order_id-1];
      new_order.id = new_order_id;
      new_order.owner = msg.sender;
      
      new_order.daily_dist_id = daily_dist.id;
      new_order.dist_period_id = dist_period.id;
      
      if (_ref != msg.sender && _ref != address(0x0)) {
        new_order.ref = _ref;
        new_order.influence_value = self.influence_value[_ref];
        daily_dist.ref_order_amount += new_order.influence_value;
      }
      
      daily_dist.order_ids.push(new_order.id);
      daily_dist.find_order_id_by_address[new_order.owner] = new_order.id;
      
      self.find_orders[msg.sender].push(new_order.id);
      
      if(self.find_referral_address[bytes8(sha256(msg.sender))] == address(0x0)) self.find_referral_address[bytes8(sha256(msg.sender))] = msg.sender;
          
      //DebugString("find_orders");
      //DebugUInt(self.find_orders[msg.sender].length);
      //DebugAddress(msg.sender);
    }
    
    Types.Order storage order = self.orders[daily_dist.find_order_id_by_address[msg.sender]-1];
    
    uint256 dev_fund_fee = msg.value * 10 / 100;
    uint256 new_order_value = msg.value - dev_fund_fee;
    order.value += msg.value;
    
    
    self.influence_value[msg.sender] += order.value;
    daily_dist.amount_in_orders += order.value;
    
    
    if (!CoreLib2.HasColdStorage(self, msg.sender)) CoreLib3.CreateColdStorage(self, msg.sender);
    ColdStorageInterface cold_storage = ColdStorageInterface(CoreLib2.GetColdStorage(self, msg.sender));
    VirtualWalletInterface dev_wallet = VirtualWalletInterface(CoreLib2.GetVirtualWallet(self, data.owner));
    
    //DebugString("Buy order created");
    //DebugUInt(address(this).balance);
    //DebugUInt(msg.value);
    //DebugUInt(dev_fund_fee);
    //DebugUInt(new_order_value);
    
    require(cold_storage.call.value(new_order_value)());
    self.locked_ether_amount = self.locked_ether_amount.add(new_order_value);
    require(dev_wallet.call.value(dev_fund_fee)());

    //DebugUInt(address(this).balance);
    //DebugUInt(cold_storage.balance);
    //DebugUInt(dev_wallet.balance);
    
    BuyOrderCreated(dist_period.id, daily_dist.id, order.id, msg.value);
    
    return order.id;
  }

  function FindCurrentDailyDistributionID(Types.DataContainer storage self,Types.DistPeriod storage current_dist_period) returns(uint256) {
    uint256 seconds_since_start = block.timestamp.add(self._tmp_timeshift).sub(current_dist_period.start_time);
    uint256 current_dist_day = (seconds_since_start.div(RemoteWalletLib.GetSecondsInADay()))+1; //1-..
    
    uint256 current_daily_dist_id = current_dist_period.find_daily_dist_id_by_day[current_dist_day];
    return current_daily_dist_id;
  }


  //Also returns upcoming distribution
  function GetCurrentDistributionPeriod(Types.DataContainer storage self) constant returns(uint256) {
    uint256 distributions = self.dist_periods.length;
    uint current_distribution_id = 0;
    uint256 current_timestamp = block.timestamp.add(self._tmp_timeshift);
    Types.DistPeriod storage tmp_dist_period;
    uint256 i;
    
    //Only allow refunds outside of a distribution period. 
    for (i = 0; i < distributions; i++) {
      tmp_dist_period = self.dist_periods[i];
      bool inside_distribution = current_timestamp >= tmp_dist_period.start_time && current_timestamp < tmp_dist_period.end_time;
      if (inside_distribution) {
        current_distribution_id = tmp_dist_period.id;
        return current_distribution_id;
      }
    }
    
    //Not in any distribution, check for upcoming
    //Only works with sorted list of distributions.
    for (i = 0; i < distributions; i++) {
      tmp_dist_period = self.dist_periods[i];
      
      if (current_timestamp <= tmp_dist_period.start_time) {
        current_distribution_id = tmp_dist_period.id;
        return current_distribution_id;
      }
    }
    
    return 0;
  }
  
  function GetDistributionStruct1(Types.DataContainer storage self, uint256 _dist_period_id) constant returns(
        uint256 ether_gathered,
        uint256 tokens_released,
        uint256 tokens_total,
        bool ended,
        uint256 start_time,
        uint256 end_time,
        uint256 days_total)
  {
    Types.DistPeriod storage dist_period = self.dist_periods[_dist_period_id-1];
    return(
        dist_period.dist.ether_gathered,
        dist_period.dist.tokens_released,
        dist_period.dist.tokens_total,
        dist_period.dist.ended,
        dist_period.start_time,
        dist_period.end_time,
        dist_period.days_total);
  }
  
  function GetDistributionStruct2(Types.DataContainer storage self, uint256 _dist_period_id) constant returns(
        uint256 descending_amount,
        bytes32 caption,
        uint256 amount,
        uint256 daily_amount,
        uint256 ref_reserve_percentage,
        uint256 recent_daily_dist_id)
  {
    Types.DistPeriod storage dist_period = self.dist_periods[_dist_period_id-1];
    return(
        dist_period.descending_amount,
        dist_period.caption,
        dist_period.amount,
        dist_period.daily_amount,
        dist_period.ref_reserve_percentage,
        dist_period.recent_daily_dist_id);
  }
  
  function GetDailyDistributionStruct1(Types.DataContainer storage self, uint256 _dist_period_id, uint256 _daily_dist_id) constant returns(
        uint256 day,
        uint256 start_time,
        uint256 end_time,
        uint256 daily_amount,
        uint256 ref_order_amount,
        uint256 amount_in_orders)
  {
    Types.DistPeriod storage current_dist_period = self.dist_periods[_dist_period_id-1];
    Types.DailyDist storage current_daily_dist = current_dist_period.daily_dists[_daily_dist_id-1];
    return(
        current_daily_dist.day,
        current_daily_dist.start_time,
        current_daily_dist.end_time,
        current_daily_dist.daily_amount,
        current_daily_dist.ref_order_amount,
        current_daily_dist.amount_in_orders);
  }
  
  function GetDailyDistributionStruct2(Types.DataContainer storage self, uint256 _dist_period_id, uint256 _daily_dist_id) constant returns(
        uint256 ether_gathered,
        uint256 tokens_released,
        uint256 tokens_total,
        bool ended)
  {
    Types.DistPeriod storage current_dist_period = self.dist_periods[_dist_period_id-1];
    Types.DailyDist storage current_daily_dist = current_dist_period.daily_dists[_daily_dist_id-1];
    return(
        current_daily_dist.dist.ether_gathered,
        current_daily_dist.dist.tokens_released,
        current_daily_dist.dist.tokens_total,
        current_daily_dist.dist.ended);
  }

  
  function GetOrderStruct(Types.DataContainer storage self, uint256 _order_id) constant returns(
        uint256 value,
        uint256 dist_period_id,
        uint256 daily_dist_id,
        uint256 received_tokens,
        bool processed,
        address owner,
        address ref,
        uint256 influence_value)
  {
    Types.Order storage order = self.orders[_order_id-1];
    return(
        order.value,
        order.dist_period_id,
        order.daily_dist_id,
        order.received_tokens,
        order.processed,
        order.owner,
        order.ref,
        order.influence_value);
  }
  
  function GetCurrentDailyDistributionDay(Types.DataContainer storage self, uint256 _dist_period_id) constant returns(uint256) {
    require(_dist_period_id > 0 && _dist_period_id <= self.dist_periods.length);
    Types.DistPeriod storage current_dist_period = self.dist_periods[_dist_period_id-1];
    
    return FindCurrentDailyDistributionID(self, current_dist_period);
  }
  

  function Distribute(Types.DataContainer storage self, bool _absolute, uint256 _start_time, uint256 _days, uint256 _amount, uint256 _descending_amount, bytes32 _caption) returns(uint256) {
    if (_start_time == 0) _start_time = block.timestamp.add(self._tmp_timeshift);
    else {
      if (!_absolute) _start_time =  block.timestamp.add(self._tmp_timeshift).add(_start_time); //Shift
    }
    require(_start_time >= block.timestamp.add(self._tmp_timeshift));
    require(_days > 0);
    require(_amount > 0);
    
    //Make sure it can be evenly distributed
    require(_amount.sub((_amount.div(_days)).mul(_days)) == 0);
    
    uint256 end_time = _start_time + _days.mul(RemoteWalletLib.GetSecondsInADay());
    
    //make sure no collisions occur
    for (uint256 i = 0; i < self.dist_periods.length; i++) {
      Types.DistPeriod storage tmp_dist_period = self.dist_periods[i];
      bool collides = end_time > tmp_dist_period.start_time && _start_time < tmp_dist_period.end_time;
      require(!collides);
    }
    
    self.distributed += _amount;
    
    //Create a new dist period.
    return CreateDistributionPeriod(self, _start_time, _days, _amount, _descending_amount, _caption);
  }
  
   function CreateDistributionPeriod(Types.DataContainer storage self, uint256 _start_time, uint256 _days, uint256 _amount, uint256 _descending_amount, bytes32 _caption) returns(uint256) {
    self.dist_periods.length++;
    uint256 new_dist_period_id = self.dist_periods.length;
    Types.DistPeriod storage new_dist_period = self.dist_periods[new_dist_period_id-1];
    
    new_dist_period.id = new_dist_period_id;
    new_dist_period.start_time = _start_time;
    new_dist_period.end_time = _start_time.add(_days.mul(RemoteWalletLib.GetSecondsInADay()));
    new_dist_period.days_total = _days;
    new_dist_period.amount = _amount;
    new_dist_period.daily_amount = _amount.div(_days);
    new_dist_period.ref_reserve_percentage = 5; //max of 5% will be split between referals
    new_dist_period.caption = _caption;
    new_dist_period.descending_amount = _descending_amount;
    
    uint256 bonus_amount = _descending_amount.div(_days);
    uint256 series_sum = (_days * (_days - 1 )).div(2) * bonus_amount;
    
    for (uint256 i = 1; i <= _days; i++) {
      CreateDailyDistribution(self, new_dist_period, i, (new_dist_period.amount - series_sum).div(_days) + bonus_amount * (_days - i));
    }
    
    new_dist_period.dist.tokens_total = _amount;
    
    NewDistributionPeriod(new_dist_period_id);
    
    return new_dist_period_id;
  }
  

  function CreateDailyDistribution(Types.DataContainer storage self, Types.DistPeriod storage current_dist_period, uint256 _day, uint256 _amount) returns(uint256) {
      current_dist_period.daily_dists.length++;
      uint256 current_daily_dist_id = current_dist_period.daily_dists.length;
      current_dist_period.find_daily_dist_id_by_day[_day] = current_daily_dist_id;
      
      Types.DailyDist storage current_daily_dist = current_dist_period.daily_dists[current_daily_dist_id-1];
      current_daily_dist.id = current_daily_dist_id;
      current_daily_dist.day = _day;
      current_daily_dist.daily_amount = _amount;
      current_daily_dist.start_time = current_dist_period.start_time.add((_day-1).mul(RemoteWalletLib.GetSecondsInADay()));
      current_daily_dist.end_time = current_dist_period.start_time.add(_day.mul(RemoteWalletLib.GetSecondsInADay()));
      
      return current_daily_dist_id;
  }
  
  
  function _InitSpecialPermissions(Types.DataContainer storage self, RemoteWalletLib.RemoteWalletData storage data) {
    //SuperMajority group controls over foundation tokens
    TokenStorageInterface foundation_tokens = TokenStorageInterface(self.tokens_for_distribution);
    foundation_tokens.APISetPermissionBySig(bytes4(sha3("APISuperMajorityCall(address,bytes4)")), self.supermajority_group, true, false);
    
    //SuperMajority group controls over foundation wallet
    VirtualWalletInterface foundation_wallet = VirtualWalletInterface(self.foundation_virtual_wallet);
    foundation_wallet.APISetPermissionBySig(bytes4(sha3("APISuperMajorityCall(address,bytes4)")), self.supermajority_group, true, false);
    
    //Which functions supermajority is allowed to call
    RemoteWalletLib._SetPermissionBySig(data, bytes4(sha3("SetBurnRequired(bool)")), self.supermajority_group, true, true); //Can disable token burn during refund, however it can have negative impact on economy. It's a double-edged sword.
    RemoteWalletLib._SetPermissionBySig(data, bytes4(sha3("SetSuperMajorityAddress(address)")), self.supermajority_group, true, true); //Can upgrade itself, however won't change permissions required.
  }
  
  function SetSuperMajorityAddress(Types.DataContainer storage self, RemoteWalletLib.RemoteWalletData storage data, address _supermajority) {
    self.supermajority_group = _supermajority;
    _InitSpecialPermissions(self, data);
  }
  
  function max(uint256 a, uint256 b) constant returns (uint256) {
      return (a>b)?a:b;
  }
  
  function min(uint256 a, uint256 b) constant returns (uint256) {
      return !(a>b)?a:b;
  }
  
}