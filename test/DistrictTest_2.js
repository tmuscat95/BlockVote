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

    afterEach(async () => {
        await voteToken.kill();
        await district.kill();
    });

    it("Should Show correct number of 1st count votes for both parties (0 5) after voting",async ()=>{
        for(let i = 6; i<=10; i++){
            //console.log(i);
            //castVote(candidateAddresses.slice(0,5), i);
            await voteToken.mint(accounts[0], i, districtNo);
            await voteToken.setApprovalForAll(district.address,true);

            await district.vote(i,candidateAddresses.slice(5,10));
        //console.log(i);
            for(let j = 1; j<=5; j++)
                console.log(await voteToken.preferences(i,j));
            
        }

        await district.countVotes();
        {let _01stCount = await district.party1stCountVotes(0);
        assert.equal(_01stCount,0,"Party index 0 incorrect number of votes.");
        let _11stCount = await district.party1stCountVotes(1);
        assert.equal(_11stCount,5,"Party index 0 incorrect number of votes.");}

        console.log("QUOTA:" + await district.getQuota());
        candidateAddresses.slice(5,10).forEach(async (candidateAddress) =>{
            let candidateStruct = await district.candidates(candidateAddress);
            console.log(candidateAddress +" "+candidateStruct.elected);
            assert.equal(candidateStruct.elected,true);
        });
    });
});