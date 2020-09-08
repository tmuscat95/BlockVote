const chai = require("chai");
const expect = chai.expect;
const assert = chai.assert;
const truffleAssert = require('truffle-assertions');
chai.should();

const VoteToken = artifacts.require("./VoteToken.sol");
const District = artifacts.require("./District.sol");

contract("District" , async accounts => {
    var voteToken;
    var district;
    const districtNo = 13;
    var candidateAddresses;
    var candidateStructs;

    beforeEach(async () => {
        let voteStart = 0;
        let voteEnd = Date.now() + 99999999999;
        let name = "TEST";
        voteToken = await VoteToken.new(name,"",voteStart,voteEnd);
        
        candidateAddresses = [];
        for(let i = 0; i < 10; i++)
            candidateAddresses.push(await web3.eth.accounts.create().address);
        
        candidateStructs = [];

        candidateAddresses.slice(0,5).forEach( (_address) => {
            candidateStructs.push([
                _address, // _address
                0, //party
                districtNo, //districtNo
                0, // elected
                0, //eliminated
                0
            ]);
        });

        candidateAddresses.slice(5,10).forEach( (_address) => {
            candidateStructs.push([
                _address, // _address
                1, //party
                districtNo, //districtNo
                0, // elected
                0, //eliminated
                0
            ]);
        });
        
        district = await District.new(districtNo, candidateStructs);
        voteToken.setAllowed(district.address);
        await district.setVoteToken(voteToken.address);
        
        console.log("Candidates Count: " + await district.candidatesCount());
        console.log(candidateStructs);
    });

   

    it("Vote function does not revert when attempting to vote with a VoteToken instance having the correct district number (13). And increases cast votes count. ie: voting succeeds", async () => {
        let tokenId = 1;
        voteToken.mint(accounts[0], tokenId, 13);
        voteToken.setApprovalForAll(district.address,true);

        await truffleAssert.passes(district.vote(tokenId,candidateAddresses.slice(0,5)), "Reverts vote function transaction on receiving a token with correct district number.");
        assert.equal(await district.castVotes(),1);
    });

    it("Vote function sets voting preferences correctly", async () => {
        let tokenId = 1;
        voteToken.mint(accounts[0], tokenId, 13);
        voteToken.setApprovalForAll(district.address,true);

        await truffleAssert.passes(district.vote(tokenId,candidateAddresses.slice(0,5)), "Reverts vote function transaction on receiving a token with correct district number.");
        assert.equal(await district.castVotes(),1);
        for(let i =0; i < candidateAddresses.slice(0,5).length; i++){
            let x = await voteToken.preferences(tokenId,i+1);
            //console.log(x +", " + candidateAddresses.slice(0,5)[i]);
            assert.equal(x,candidateAddresses.slice(0,5)[i]);
        }
    });

    it("Vote function reverts when attempting to vote with a VoteToken instance having the incorrect district number. (13)", async () => {
        voteToken.mint(accounts[0], 1, 12);
        voteToken.setApprovalForAll(district.address,true);

        await truffleAssert.reverts(district.vote(1,candidateAddresses.slice(0,5)),"Incorrect District", "Does not Revert vote function transaction on receiving a token with incorrect district number.");


    });

    it("getQuota() returns correct values", async () => {
       //By mathematical induction
       //For all castVotes < seats + 1 (seats == 5) quota == 1
        assert.equal(await district.getQuota(),1); // castVotes == 0

        let tokenId = 1;
        await voteToken.mint(accounts[0], tokenId, 13);
        await voteToken.setApprovalForAll(district.address,true);
        await truffleAssert.passes(district.vote(tokenId,candidateAddresses.slice(0,5)));
        assert.equal(await district.getQuota(),1); // castVotes == 1

        tokenId = 2;
        await voteToken.mint(accounts[0], tokenId, 13);
        await voteToken.setApprovalForAll(district.address,true);
        await truffleAssert.passes(district.vote(tokenId,candidateAddresses.slice(0,5)));
        assert.equal(await district.getQuota(),1); // castVotes == 2

        
    });

    it("Should transfer all tokens back to owner, and revert if caller is not District to which that token corresponds", async () => {
        await voteToken.mint(accounts[0],2,13);
        await voteToken.setApprovalForAll(district.address,true); //{from: accounts[0]}
        //var district = new District();

        let districtBalance = await voteToken.balanceOf(district.address);
        let otherBalance = await voteToken.balanceOf(accounts[0]);

        //assert.equal(ownerBalance,0);
        assert.equal(otherBalance,1,"Mint Failed");
        assert.equal(districtBalance,0);

        await truffleAssert.passes(district.transferAllBack(accounts[0]));
        let _districtBalance = await voteToken.balanceOf(district.address);
        assert.equal(_districtBalance.toNumber(), districtBalance.toNumber() + otherBalance.toNumber());

        await voteToken.mint(accounts[1],3,13);
        await truffleAssert.reverts(district.transferAllBack(accounts[1]),"ERC721: transfer caller is not owner nor approved.");
        
        
            
        await voteToken.mint(accounts[0],4,12);
        await truffleAssert.reverts(district.transferAllBack(accounts[0]),"Attempting to seize token from another district.");
  });

  it('Given 5 cast votes (and a corresponding quota of 1) each selecting the same 5 candidates from the same party (id 0), each candidate should end up with 1 vote and be marked as elected. party\'s index should map to 5 in the party1stCountVotes mapping', async () => {
        
    for(let i = 1; i<=5; i++){
        //console.log(i);
        //castVote(candidateAddresses.slice(0,5), i);
        await voteToken.mint(accounts[0], i, districtNo);
        await voteToken.setApprovalForAll(district.address,true);

        await district.vote(i,candidateAddresses.slice(0,5));
       //console.log(i);
        for(let j = 1; j<=5; j++)
            console.log(await voteToken.preferences(i,j));
        
    }
    
    assert.equal(await district.castVotes(),5,"Wrong number of cast votes.");
    assert.equal(await district.candidatesCount(),10,"Candidates count is not 10 before vote counting");
    await district.countVotes();
    assert.equal(await district.candidatesCount(),10,"Candidates count is not 10 after vote counting");

    
    console.log(candidateAddresses.slice(0,5));
    var i = 0;
    candidateAddresses.slice(0,5).forEach(async (candidateAddress) =>{
        //console.log(i++);
        let balance = await voteToken.balanceOf(candidateAddress);
        //console.log("Candidate Index " + i +" " + balance.toString());
        //console.log(await district.candidates(candidateAddress));
        assert.equal(1,balance,candidateAddress +" " + i + " Incorrect Balance.");
        i++;
    });

    console.log(candidateAddresses.slice(5,10));
    i = 0;
    candidateAddresses.slice(5,10).forEach(async (candidateAddress) =>{
        //console.log(i++);
        let balance = await voteToken.balanceOf(candidateAddress);
        //console.log("Candidate Index " + i +" " + balance.toString());
        //console.log(await district.candidates(candidateAddress));
        assert.equal(0,balance,candidateAddress +" " + i + " Incorrect Balance.");
        i++;
    });
});
    

});