pragma solidity ^0.4.11;


import './SafeMathLib.sol';
import './ColdStorage.sol';

library CoreLib3 {
  using SafeMathLib for uint256;
      
  function CreateColdStorage(Types.DataContainer storage self, address _address) returns(address) {
    if (self.find_cold_storage[_address] == address(0x0)) {
      
      self.find_cold_storage[_address] = new ColdStorage(address(this), _address);
      self.find_owner_by_smart_wallet_address[self.find_cold_storage[_address]] = _address;

      self.cold_storages.push(self.find_cold_storage[_address]);
    }
    return self.find_cold_storage[_address];
  }

}