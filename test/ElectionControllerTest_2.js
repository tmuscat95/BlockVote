
const chai = require("chai");
const expect = chai.expect;
const assert = chai.assert;
const truffleAssert = require('truffle-assertions');
const { contracts_build_directory } = require("../truffle-config");
chai.should();

const ElectionController = artifacts.require("./ElectionController.sol");
const DistrictFactory = artifacts.require("./DistrictFactory.sol");
const VoteTokenFactory = artifacts.require("./VoteTokenFactory.sol");
const District = artifacts.require("./District.sol");
const VoteToken = artifacts.require("./VoteToken.sol");

contract("ElectionController",async (accounts) => {
    var electionController;
    var districtFactory;
    var voteTokenFactory;
    var candidates;
    var _name;
    var _voteStart;
    var _voteEnd;
    var districtsNo;
    var numberOfPartiesContesting;
 
    beforeEach( async () => {
        districtsNo = 13;
        numberOfPartiesContesting = 2;
        districtFactory = await DistrictFactory.new();
        voteTokenFactory = await VoteTokenFactory.new();
        candidates = [];
        candidateAddresses = [];
        _name = "TEST";
        _voteStart = 0;
        _voteEnd = Date.now() + 999999999;
        
        
        //console.log(voteToken);
    });

    it("Election Should End with correct results",async ()=>{
        electionController = await ElectionController.new(districtsNo,districtFactory.address,voteTokenFactory.address);

        for (let i=0;i<districtsNo;i++){
            candidates.push([]);
            candidateAddresses.push([]);

            for(let j=0;j<5;j++){
                let a = await web3.eth.accounts.create().address;
                candidateAddresses[i].push(a);
                candidates[i].push([
                    a,//await web3.eth.accounts.create(),//address
                    0, //Party
                    i+1, //District No
                    false, //elected
                    false, //eliminated
                    0
                ]);
            }
            
            for(let j=5;j<10;j++){
                let a = await web3.eth.accounts.create().address;
                candidateAddresses[i].push(a);
                candidates[i].push([
                    a,//await web3.eth.accounts.create(),//address
                    1, //Party
                    i+1, //District No
                    false, //elected
                    false, //eliminated
                    0
                ]);
            }
        }

        //console.log(candidates);
        await electionController.launchElection(_name,_voteStart,_voteEnd,numberOfPartiesContesting,candidates);
        var election = await electionController.elections(0);
        var voteToken = await VoteToken.at(election.voteToken);
        //console.log(election);
        //console.log(voteToken);

        var id = 0;
        for(let i = 0; i<13; i++){
            let d = await electionController.getDistrictContract(0,i+1);
            //console.log(d);
            let district = await District.at(d);
            console.log(district.address);
            
            for(let j = 0; j<2;j++){
                //2 votes for party 1 on each district, for 5 candidates from party 1
                await electionController.mintVote(accounts[0], ++id, i+1,0);
                await voteToken.setApprovalForAll(district.address,true);
                await district.vote(id,candidateAddresses[i].slice(5,10));
                const mu = process.memoryUsage();
                console.log(mu);
            }

            /*
            for(let j = 0; j<1;j++){
                //2 votes for party 1 on each district, for 5 candidates from party 1
                await electionController.mintVote(accounts[0], ++id, i+1,0);
                await voteToken.setApprovalForAll(district.address,true);
                await district.vote(id,candidateAddresses[i].slice(0,5));
                const mu = process.memoryUsage();
                console.log(mu);
            }*/

         
        }


           //1 vote for party 0 on each district, for 5 candidates from party 0
        
        let d = await electionController.getDistrictContract(0,1);
           //console.log(d);
        let district = await District.at(d);
        await electionController.mintVote(accounts[0], ++id, 1,0);
        await voteToken.setApprovalForAll(district.address,true);/*
        await district.vote(id,candidateAddresses[0].slice(0,1));
        const mu = process.memoryUsage();
        console.log(mu);
        console.log(candidateAddresses[0].slice(0,5));*/

        election = await electionController.elections(0);
        console.log(election);
        assert.notEqual(await electionController.districtsNo(),0);
        
        await electionController.endElection(0);
       
        election = await electionController.elections(0);
        console.log(election);
        assert.equal(election.partyWithMostVotesIndex,1);
        
    });

});