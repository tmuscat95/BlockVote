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
    const districtsNo = 13;
    const numberOfPartiesContesting = 2;

    beforeEach( async () => {
        
        districtFactory = await DistrictFactory.new();
        voteTokenFactory = await VoteTokenFactory.new();
        candidates = [];
        candidateAddresses = [];
        _name = "TEST";
        _voteStart = 0;
        _voteEnd = Date.now() + 999999999;
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
        
        //console.log(voteToken);
    });

    /*it('', () => {
        
    });*/


   it("Should push an election with the correct parameters", async ()=>{
        let election = await electionController.elections(0);
        console.log(election);
        console.log(election.name);
        assert.equal(_name,election.name);
        assert.equal(_voteStart,election.voteStart);
        assert.equal(_voteEnd,election.voteEnd);
        assert.equal(await electionController.districtsNo(),13);
        
        let voteToken = await VoteToken.at(election.voteToken);
        assert.equal(_name,await voteToken.name());
        assert.equal(_voteStart,await voteToken.voteStart());
        assert.equal(_voteEnd,await voteToken.voteEnd());

        for(let i=1;i<=13;i++){
            let districtContract = await District.at(await electionController.getDistrictContract(0,i));
            
            assert.equal(i,await districtContract.districtNumber());
            assert.equal(election.voteToken,await districtContract.voteToken());

            var districtCandidateAddresses = await electionController.getDistrictCandidateAddresses(0,i);
            console.log(districtCandidateAddresses);
            assert.equal(10,districtCandidateAddresses.length);

            for(let j = 0; j<10; j++)
                assert.equal(candidates[i-1][j][0],districtCandidateAddresses[j]);
        }
    });

    it("mintVote should increase vote balance of controller contract. Should revert if address already has vote",async ()=>{
        let address = await web3.eth.accounts.create().address;
        await electionController.mintVote(1,13,0);

        let balance = await electionController.balanceOf(electionController.address,0);
        //console.log(balance.toNumber());
        assert.equal(balance,1);

        await truffleAssert.reverts(electionController.mintVote(1,13,0),"ERC721: token already minted.");
        
        let election = await electionController.elections(0);
        //console.log(election);
        let voteToken = await VoteToken.at(election.voteToken);
        await truffleAssert.reverts(voteToken.mint(address,1,13),"Ownable: caller is not the owner");
    });
    
});