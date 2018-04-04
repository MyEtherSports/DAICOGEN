const MyEtherSportsJS = require('./MyEtherSports.js');

import increaseTime from './helpers/increaseTime.js';
import expectEvent from './helpers/expectEvent.js';
import expectThrow from './helpers/expectThrow.js';
import assertRevert from './helpers/assertRevert.js';

var VirtualWallet = artifacts.require("./VirtualWallet.sol");
var SuperMajority = artifacts.require("./MyEtherSports.sol");
var TokenStorage = artifacts.require("./TokenStorage.sol");
var ColdStorage = artifacts.require("./ColdStorage.sol");

var Action = artifacts.require("./Action.sol");
var DummyParent = artifacts.require("./DummyParent.sol");

String.prototype.format = String.prototype.f = function() {
    var s = this,
        i = arguments.length;

    while (i--) {
        s = s.replace(new RegExp('\\{' + i + '\\}', 'gm'), arguments[i]);
    }
    return s;
};

var timeshift = 0;
const seconds_in_a_day = 86400;
var ForwardTime = async function(days) {
    //await myethersports._TMP_forward_time(days);
    await increaseTime(days * seconds_in_a_day);
    timeshift += days;
}

const promisify = (inner) =>
  new Promise((resolve, reject) =>
    inner((err, res) => {
      if (err) { reject(err) }
      resolve(res);
    })
  );
  
const getBalance = (account, at) => promisify(cb => web3.eth.getBalance(account, at, cb));

const sendTransaction = (_from, _to, _value) => promisify(cb => web3.eth.sendTransaction({from: _from, to: _to, value: _value}), cb);


contract('Scenario', (accounts) => {

    let myethersports;
    let supermajority;
  
    it("should have the shared context", async() => {
        context = await MyEtherSportsJS.run(accounts);
        myethersports = context.myethersports;
        supermajority = context.supermajority;
    
        assert(myethersports !== undefined, 'has MyEtherSports instance');
        assert(supermajority !== undefined, 'has SuperMajority instance');
    });

    it("should post-initialize", async() => {
        //==== First call
        await myethersports.PostInit();
        
        var foundation_virtual_wallet_address = await myethersports.GetVirtualWallet(accounts[0]);
        var foundation_virtual_wallet = VirtualWallet.at(foundation_virtual_wallet_address);
        var foundation_daily_ether_amount = await foundation_virtual_wallet.APIGetDailyAmount.call()
        foundation_daily_ether_amount = web3.fromWei(foundation_daily_ether_amount.toNumber());
        
        console.info(foundation_daily_ether_amount);
        assert(foundation_daily_ether_amount == 5, 'must have 5 ether daily limit');
        
        
        //==== Second call
        await myethersports.PostInit();
        
        var distribution_token_storage = await myethersports.GetTokenStorage(myethersports.address);
        var tokens_for_distribution = await myethersports.balanceOf(distribution_token_storage);
        tokens_for_distribution = tokens_for_distribution.toNumber();
        console.info(tokens_for_distribution);
        assert(tokens_for_distribution == 90000000 * 100000000, 'must have 90% of total supply');
        
        //==== Third call
        await myethersports.PostInit();
        
        var foundation_token_wallet = await myethersports.GetTokenStorage(accounts[0]);
        var foundation_tokens = await myethersports.balanceOf(foundation_token_wallet);
        foundation_tokens = foundation_tokens.toNumber();
        console.info(foundation_tokens);
        assert(foundation_tokens == 8000000 * 100000000, 'foundation should receive 8%');
        
    });
  
    it("should add angel investors", async() => {
        await myethersports.AddAngelInvestors();
        await myethersports.AddAngelInvestors();
        await myethersports.AddAngelInvestors();
    });
    
    
    it("set supermajority group", async() => {
        console.info("SuperMajority");
        console.info(supermajority.address);
        
        await expectThrow(myethersports.SetSuperMajorityAddress(supermajority.address, {from: accounts[1]})); //Unauthorized
        
        await myethersports.SetSuperMajorityAddress(supermajority.address);
        
        await  expectThrow(myethersports.SetSuperMajorityAddress(supermajority.address)); //can't set twice
        
        var supermajority_address = await myethersports.GetSuperMajorityWallet.call();
        console.info(supermajority_address);
        
        assert(supermajority.address == supermajority_address, "couldn't assign supermajority");
    });
    
    it("test supermajority time lock", async() => {
        await expectThrow(supermajority.APICreateProposal("Early proposal", myethersports.address, accounts[3], "RemoteCall()", {from: accounts[2]}));
    });
    
    it("should create distributions", async() => {
        await expectThrow(PlaceOrder(accounts[1], web3.toDecimal(web3.toWei(1, 'ether')), 0x0)); //Too early
        
        
        var created = await myethersports.GetCreationDate.call();
        created = created.toNumber();
        
        //await myethersports.Distribute(0, false, 30, 2700000000000000, 12000000000000, "Spring");
        await myethersports.Distribute(created+seconds_in_a_day, true, 30, 2700000000000000, 12000000000000, "Spring");
        
        var dist_struct = await myethersports.GetDistributionStruct1.call(1);
        var first_dist_start_time = dist_struct[4].toNumber();
        
        console.info(created);
        console.info(seconds_in_a_day);
        console.info(created + seconds_in_a_day);
        console.info(first_dist_start_time);
        
        await ForwardTime(1);
        
        await expectThrow(myethersports.ForceMajeure());
        
        await myethersports.Distribute(first_dist_start_time + 7776000, true, 30, 2400000000000000, 12000000000000, "Summer");
        await myethersports.Distribute(first_dist_start_time + 15552000, true, 30, 2100000000000000, 12000000000000, "Autumn");
        await myethersports.Distribute(first_dist_start_time + 23328000, true, 30, 1800000000000000, 12000000000000, "Winter");
    });
    
    
    it("no self referrals", async() => {
        await PlaceOrder(accounts[1], web3.toWei(1, 'ether'), 0x0);
        await expectThrow(PlaceOrder(accounts[1], web3.toWei(1, 'ether'), accounts[1]));
    });
    
    
    var PlaceOrder = async function(_from, _amount, _ref) {
        var old_balance = await getBalance(_from);
        
        var account_ref = await myethersports.GetReferralLink.call(_ref);
        
        await myethersports.PlaceOrder(account_ref, {value: _amount, from: _from});
        
        var balance = await getBalance(_from);
        var cold_storage = await myethersports.GetColdStorage(_from);
        var cold_storage_balance = await getBalance(cold_storage);
    }
    
    var ClaimTokens = async function(_for) {
        await myethersports.ClaimMyTokens(0, {from: _for});
        
        var balance = await myethersports.balanceOf(_for);
        return balance.toNumber();
    }
     
     var PlaceOrder10 = async function() {
            for (var x = 1; x < 10; x++) {
                var to_send = web3.toDecimal(web3.toWei(Math.random(), 'ether')) + web3.toDecimal(web3.toWei(0.01, 'ether')); //Math.random()
                var ref_id = (Math.round(Math.random() * 10) % 10);
                try {
                    await PlaceOrder(accounts[x], to_send, accounts[ref_id]); //accounts[1+(Math.round(Math.random() * 10) % 10)]
                }
                catch(err) {
                    await PlaceOrder(accounts[x], to_send, 0x0);
                    console.info("couldn't place order for {0} with ref_id {1} and amount {2}".f(x, ref_id, to_send));
                    continue;
                }
                
                //Place two orders one after another
                if (Math.round() > 0.75) {
                    console.info("ordering twice");
                    var ref_id_2 = (Math.round(Math.random() * 10) % 10); //Use a different ref_id, old one should remain
                    try {
                        await PlaceOrder(accounts[x], to_send, accounts[ref_id_2]); //accounts[1+(Math.round(Math.random() * 10) % 10)]
                    }
                    catch(err) {
                        await PlaceOrder(accounts[x], to_send, 0x0);
                        console.info("couldn't place order for {0} with ref_id {1} and amount {2}".f(x, ref_id_2, to_send));
                        continue;
                    }
                }
            }
     }
     

    var ClaimTokens10 = async function(day) {
            for (var x = 1; x < 10; x++) {
                try {
                    await ClaimTokens(accounts[x]);
                }
                catch(err) {
                    console.info("couldn't claim tokens for {0}".f(x));
                   continue;
                }
                
            }
            
            var balance = 0;
            for (var x = 1; x < 10; x++) {
                var tmp_balance = await myethersports.balanceOf(accounts[x]);
                balance += tmp_balance.toNumber();
            }
            console.info(balance);
            
            //assert(true == false, "debug");
     }
     
    var PlaceMassiveOrders = async function(amount) {
        var total = 0;
        for (var i = 0; i < amount; i++) {
                console.info("Day {0}".f(i));
                /*
                var dist_period = await myethersports.GetCurrentDistributionPeriod.call();
                var dist_day = await myethersports.GetCurrentDailyDistributionDay.call(1);
                dist_period = dist_period.toNumber();
                dist_day = dist_day.toNumber()
                console.info("DistPeriod {0}".f(dist_period));
                console.info("Dist Day {0}".f(dist_day));
                */
                await PlaceOrder10();
                await ForwardTime(1);
                /*
                console.info("Forward time...");
                dist_period = await myethersports.GetCurrentDistributionPeriod.call();
                dist_day = await myethersports.GetCurrentDailyDistributionDay.call(1);
                dist_period = dist_period.toNumber();
                dist_day = dist_day.toNumber()
                console.info("DistPeriod {0}".f(dist_period));
                console.info("Dist Day {0}".f(dist_day));
                */
                await ClaimTokens10(i);
                
                console.info("---");
        }
        for (var x = 1; x < 10; x++) {
                var tmp_balance = await myethersports.balanceOf(accounts[x]);
                total += tmp_balance.toNumber();
         }
         return total;
    }
    
    
     it("claim tokens 1-10", async() => {
         await PlaceMassiveOrders(10);
     });
     
     
    //Note that address[3] can now take refund, not address[2]
    it("should be able to change parent", async() => {
        var cold_storage_wallet = await myethersports.GetColdStorage(accounts[3]);
        var cold_storage = ColdStorage.at(cold_storage_wallet);
        var dummy_parent = await DummyParent.deployed();
        console.info(dummy_parent.address);
        
        var old_parent = await cold_storage.APIGetParent.call({from: accounts[3]});
        console.info(old_parent);
        
        await cold_storage.APIChangeParent(dummy_parent.address, {from: accounts[3]});

        var new_parent = await cold_storage.APIGetParent.call({from: accounts[3]});
        console.info(new_parent);
        
        assert(new_parent == dummy_parent.address, "parent does not match");
    });
    
    //Note that address[3] can now take refund, not address[2]
    it("should be able to restore parent", async() => {
        var cold_storage_wallet = await myethersports.GetColdStorage(accounts[3]);
        var cold_storage = ColdStorage.at(cold_storage_wallet);
        
        var old_parent = await cold_storage.APIGetParent.call({from: accounts[3]});
        console.info(old_parent);
        
        await cold_storage.APIChangeParent(myethersports.address, {from: accounts[3]});

        var new_parent = await cold_storage.APIGetParent.call({from: accounts[3]});
        console.info(new_parent);
        
        assert(new_parent == myethersports.address, "parent does not match");
    });
     
     
     it("claim tokens 11-20", async() => {
         await PlaceMassiveOrders(10);
     });
     
     
     it("claim tokens 21-30", async() => {
         await PlaceMassiveOrders(10);
         
         var balance = 0;
         for (var x = 1; x < 10; x++) {
             var tmp_balance = await myethersports.balanceOf(accounts[x]);
             balance += tmp_balance.toNumber();
         }
        
        console.info("total:");
        console.info(balance);
     });
    


   var TestSupermajority = async function(_lock) {
        
        var dev_wallet = await myethersports.GetVirtualWallet(accounts[0]);
        var dev_virtual_wallet = VirtualWallet.at(dev_wallet);
    
        var owner = await myethersports.APIGetOwner();
    
        //Try to lock out owner from calling a function
        var old_permissions = await dev_virtual_wallet.APIGetPermissionByName("APIWithdraw(uint256)", owner);
        console.info(old_permissions);
        
        var action = await Action.deployed();
        
        var proposal_id = 0;
        if (_lock == true) {
            await supermajority.APICreateProposal("Proposal", dev_wallet, action.address, "LockDevFund()", {from: accounts[1]});
        }
        
        else {
            await supermajority.APICreateProposal("Proposal", dev_wallet, action.address, "UnlockDevFund()", {from: accounts[1]});
        }
        
        if (_lock == true) proposal_id = 1;
        if (_lock == false) proposal_id = 2;
        
        console.info("Prolosal created");
        console.info(proposal_id);
        
        /*
        //Let 4 holders to vote randomly
        for (var x = 1; x < 5; x++) {
            var is_active = await supermajority.APIIsProposalActive.call(1);
            if (!is_active) break;
            try {
                await supermajority.APICastVote(1, Math.round(Math.random())+1, {from: accounts[x]}); //Vote yes on the proposal
            }
            catch(err) {
                break;
            }
        }
        */
        
        //Let remaining 4 vote Yes
        for (var x = 3; x < 10; x++) {
            var is_active = await supermajority.APIIsProposalActive.call(proposal_id);
            if (!is_active) break;
            try {
                await supermajority.APICastVote(proposal_id, 1, {from: accounts[x]}); //Vote yes on the proposal
            }
            catch(err) {
                break;
            }
        }
        
        /*
        try {
            var executed = await supermajority.APIExecuteProposal(1, {from: accounts[1]});
            console.info(executed);
        }
        catch(err) {
            console.info("supermajority not reached");
        }
        */
        
        await supermajority.APIExecuteProposal(proposal_id, {from: accounts[1]});
        
        var status = await supermajority.APIGetProposalStatus(proposal_id);
        console.info(status[0].toNumber());
        
        var new_permissions = await dev_virtual_wallet.APIGetPermissionByName("APIWithdraw(uint256)", owner);
        console.info(new_permissions);
        
        //assert(old_permissions[0] == true && old_permissions[1] == true && new_permissions[0] == false && new_permissions[1] == false, 'permission should change');
        
        
   }
   
  
    var WalletWithdraw = async function(address, amount) {
        var dev_wallet = await myethersports.GetVirtualWallet(address);
        var dev_virtual_wallet = VirtualWallet.at(dev_wallet);
        
        var wallet_owner = await dev_virtual_wallet.APIGetOwner();
        //var timeshift = await myethersports._TMP_get_time_shift.call();
        //timeshift = timeshift.toNumber();
        
        var foundation_daily_ether_amount = await dev_virtual_wallet.APIGetDailyAmount.call();
        foundation_daily_ether_amount = web3.toDecimal(web3.fromWei(foundation_daily_ether_amount.toNumber()));
        
        var balance = await getBalance(dev_wallet);
        balance = balance.toNumber();
        console.info(balance)
        
        //await expectThrow(dev_virtual_wallet.APIWithdraw(balance));
        
        var estimate = foundation_daily_ether_amount * web3.toDecimal(web3.toWei((timeshift-1), 'ether'));
        console.info(estimate);
        
        await dev_virtual_wallet.APIWithdraw(amount, {from: address});
        
        var new_balance = await getBalance(dev_wallet);
        new_balance = new_balance.toNumber();
        console.info(new_balance)
    }

   it("test supermajority, lock dev fund", async() => {
        await ForwardTime(2);
        await TestSupermajority(true);
   });    

    it("dev wallet withdraw should fail", async() => {
        await expectThrow(WalletWithdraw(accounts[0], web3.toDecimal(web3.toWei(10, 'ether'))));
    });

   it("test supermajority, unlock dev fund", async() => {
        await ForwardTime(2);
        await TestSupermajority(false);
   });
   
     it("dev wallet withdraw should not fail", async() => {
        await WalletWithdraw(accounts[0], web3.toDecimal(web3.toWei(10, 'ether')));        
    });
    
     
    //Virtual wallet uses same functionality, same should apply to ether
     it("should deposit tokens", async() => {
        var token_storage_wallet = await myethersports.GetTokenStorage.call(accounts[2]);
        console.info(token_storage_wallet);
        
        if (token_storage_wallet == 0) {
            await myethersports.CreateTokenStorage(0, {from: accounts[2]});
            token_storage_wallet = await myethersports.GetTokenStorage.call(accounts[2]);
        }
        
        console.info(token_storage_wallet);
        
        var token_storage = TokenStorage.at(token_storage_wallet);
        
        var storage_token_balance = await myethersports.balanceOf.call(token_storage_wallet);
        var my_token_balance = await myethersports.balanceOf.call(accounts[2]);
        
        storage_token_balance = storage_token_balance.toNumber();
        my_token_balance = my_token_balance.toNumber();
        
        console.info(storage_token_balance);
        console.info(my_token_balance);

        await await myethersports.transfer(token_storage_wallet, my_token_balance, {from: accounts[2]});
        await token_storage.APIUpdateTokenAmount();
        
        var new_storage_token_balance = await myethersports.balanceOf.call(token_storage_wallet);
        var my_new_token_balance = await myethersports.balanceOf.call(accounts[2]);
        
        new_storage_token_balance = new_storage_token_balance.toNumber();
        my_new_token_balance = my_new_token_balance.toNumber();
        
        console.info(new_storage_token_balance);
        console.info(my_new_token_balance);
        
        assert(my_new_token_balance == 0 && new_storage_token_balance == my_token_balance, "couldn't deposit");
        
    });
    
     it("transfer owhership test", async() => {
        var token_storage_wallet = await myethersports.GetTokenStorage.call(accounts[2]);
        var token_storage = TokenStorage.at(token_storage_wallet);
        
        console.info(token_storage_wallet);
        
        var token_storage_owner = await token_storage.APIGetOwner.call();
        console.info(token_storage_owner);
        
        await token_storage.APITransferOwnership(accounts[3], {from: accounts[2]});
        
        await expectThrow(token_storage.APISetDailyAmount(1, {from: accounts[2]})); //No longer in control
        
        var token_storage_new_owner = await token_storage.APIGetOwner.call();
        console.info(token_storage_new_owner);
        
        //require(token_storage_new_owner != token_storage_owner, "must differ");
     });
    
    //Virtual wallet uses same functionality, same should apply to ether
     it("should withdraw tokens", async() => {
        var token_storage_wallet = await myethersports.GetTokenStorage.call(accounts[3]);
        var token_storage = TokenStorage.at(token_storage_wallet);
        
        console.info(token_storage_wallet);
        
        var storage_token_balance = await myethersports.balanceOf.call(token_storage_wallet);
        var my_token_balance = await myethersports.balanceOf.call(accounts[3]);
        
    
        storage_token_balance = storage_token_balance.toNumber();
        my_token_balance = my_token_balance.toNumber();
        
        console.info(storage_token_balance);
        console.info(my_token_balance);
        
        var old_user_perm = await token_storage.APIGetPermissionByName.call("APIWithdraw(uint256)", accounts[2]);
        console.info(old_user_perm);
        
        var perm = await token_storage.APIGetPermissionByName.call("APIWithdraw(uint256)", accounts[3]);
        console.info(perm);
        
    
        await token_storage.APIWithdraw(storage_token_balance, {from: accounts[3]});
        
        var new_storage_token_balance = await myethersports.balanceOf.call(token_storage_wallet);
        var my_new_token_balance = await myethersports.balanceOf.call(accounts[3]);
        
        new_storage_token_balance = new_storage_token_balance.toNumber();
        my_new_token_balance = my_new_token_balance.toNumber();
    
        console.info(new_storage_token_balance);
        console.info(my_new_token_balance);
        
        //assert(my_new_token_balance == my_token_balance && new_storage_token_balance == 0, "couldn't withdraw");
        
    });
     
    //Note that address[3] can now take refund, not address[2]
    it("should get refund", async() => {
        await ForwardTime(4);
        
        var cold_storage_wallet = await myethersports.GetColdStorage(accounts[3]);
        
        var old_cold_storage_balance = await getBalance(cold_storage_wallet);
        var old_balance = await getBalance(accounts[3]);
        await myethersports.GetRefund({from: accounts[3]});
        var new_balance = await getBalance(accounts[3]);
        var new_cold_storage_balance = await getBalance(cold_storage_wallet);
        
        console.info(old_cold_storage_balance.toNumber());
        console.info(new_cold_storage_balance.toNumber());
        console.info(old_balance.toNumber());
        console.info(new_balance.toNumber());
        
        var gas_limit = 6469391 * 4000000000;
        assert(new_cold_storage_balance == 0, 'cold storage must be empty');
        assert(new_balance - old_balance >= old_cold_storage_balance - new_cold_storage_balance - gas_limit, 'shound have received refund');
    });
    
});