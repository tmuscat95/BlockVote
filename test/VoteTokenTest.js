/*const SimpleStorage = artifacts.require("./SimpleStorage.sol");


contract("SimpleStorage", accounts => {
  it("...should store the value 89.", async () => {
    const simpleStorageInstance = await SimpleStorage.deployed();

    // Set value of 89
    await simpleStorageInstance.set(89, { from: accounts[0] });

    // Get stored value
    const storedData = await simpleStorageInstance.get.call();

    assert.equal(storedData, 89, "The value 89 was not stored.");
  });
});*/

const chai = require("chai");
const expect = chai.expect;
const assert = chai.assert;
const truffleAssert = require('truffle-assertions');
chai.should();

//const VoteTokenFactory = artifacts.require("./VoteTokenFactory.sol");
const VoteToken = artifacts.require("./VoteToken.sol");
const District = artifacts.require("./District.sol");

contract("VoteToken", async accounts => {
  var voteStart;
  var voteEnd;
  var name;
  var voteToken;

  beforeEach(async () => {
    voteStart = Date.now();
    voteEnd = Date.now() + 9999999999;
    name = "TEST";
    voteToken = await VoteToken.new(name,"",voteStart,voteEnd,{from: accounts[0]});
  });

  it("Should have the attributes passed to it", async ()=>{
    
    assert.notEqual(voteToken, undefined,voteToken.toString());
    
    let _name = await voteToken.name();
    assert.equal(_name,name);

    let _voteEnd = await voteToken.voteEnd.call({from: accounts[0]});
    console.log(_voteEnd);

    let _voteStart = await voteToken.voteStart.call({from: accounts[0]});
    console.log(_voteStart);

    assert.equal(_voteStart, voteStart);
    assert.equal(_voteEnd,voteEnd);
  });

  it("Minting should increase balance. New token should have correct district associated with it. Should be impossible to mint new token to address that already has one.", async () => {
   
    let tokenID = 111;
    let district = 13;

    await voteToken.mint(accounts[0],tokenID,district);
    
    let _balance = await voteToken.balanceOf(accounts[0]);
    assert.equal(_balance,1,"Balance incorrect; not 1");

    let _district = await voteToken.district(tokenID);
    assert.equal(_district,district,"District incorrect."); 
  });

  it("Should revert all transactions when current time is after set voting period", async () => {
    voteStart = 1;
    voteEnd = voteStart + 1;
    name = "TEST";

    let _voteToken = await VoteToken.new(name,"",voteStart,voteEnd,{from: accounts[0]});

    await truffleAssert.reverts(_voteToken.mint(accounts[0],1,13),"Voting Not Open.","mint does not revert for non-owner calling addres outside of voting range");

    voteStart = Date.now() + 999999999;
    voteEnd = voteStart + 999999999;

    await truffleAssert.reverts(_voteToken.mint(accounts[0],1,13),"Voting Not Open.","mint does not revert for non-owner calling addres outside of voting range");

  } );

  it("Should create a mapping of uint => address from an array of n addresses where a given integer  n >= i > 0 should map to the address in the i-1 th index in the passed array. \n This mapping should be in turn accessible via the mapping 'preferences' where the tokenId passed to the setVotePreferences function should map to the mapping described above."
  , async () => {
    let _tokenId = 2;
    await voteToken.mint(accounts[0],_tokenId,13);
    let _preferences = accounts.slice(1,6);
    await voteToken.setVotePreferences(_tokenId,_preferences);

    for(let i = 1; i <= _preferences.length; i++){
      assert.equal(await voteToken.preferences(_tokenId,i),_preferences[i-1],"voteToken(tokenId,i) != _preferences[i-1]");
    }
  });
});

