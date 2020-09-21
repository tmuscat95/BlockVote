const chai = require("chai");
const expect = chai.expect;
const assert = chai.assert;
const truffleAssert = require('truffle-assertions');
const { contracts_build_directory } = require("../truffle-config");
const readXlsxFile = require('read-excel-file/node');
const fs = require('fs');
//const web3 = require('Web3');

chai.should();

const ElectionController = artifacts.require("./ElectionController.sol");
const DistrictFactory = artifacts.require("./DistrictFactory.sol");
const VoteTokenFactory = artifacts.require("./VoteTokenFactory.sol");
const District = artifacts.require("./District.sol");
const VoteToken = artifacts.require("./VoteToken.sol");

const schema = {
    'Name' : {
        prop: 'name',
        type: String
    },
    'PARTY' : {
        prop: 'party',
        type: String
    },
    'Ct1' : {
        prop: 'count1',
        type: Number
    },
'Ct1t' : {
        prop: 'count1_transferred',
        type: Number
},

'Ct2' : {
        prop: 'count2',
        type: Number
    },
'Ct2t' : {
        prop: 'count2_transferred',
        type: Number
},

'Ct3' : {
        prop: 'count3',
        type: Number
    },
'Ct3t' : {
        prop: 'count3_transferred',
        type: Number
},

'Ct4' : {
        prop: 'count4',
        type: Number
    },
'Ct4t' : {
        prop: 'count4_transferred',
        type: Number
},

'Ct5' : {
        prop: 'count5',
        type: Number
    },
'Ct5t' : {
        prop: 'count5_transferred',
        type: Number
},

'Ct6' : {
        prop: 'count6',
        type: Number
    },
'Ct6t' : {
        prop: 'count6_transferred',
        type: Number
},

'Ct7' : {
        prop: 'count7',
        type: Number
    },
'Ct7t' : {
        prop: 'count7_transferred',
        type: Number
},

'Ct8' : {
        prop: 'count8',
        type: Number
    },
'Ct8t' : {
        prop: 'count8_transferred',
        type: Number
},

'Ct9' : {
        prop: 'count9',
        type: Number
    },
'Ct9t' : {
        prop: 'count9_transferred',
        type: Number
},

'Ct10' : {
        prop: 'count10',
        type: Number
    },
'Ct10t' : {
        prop: 'count10_transferred',
        type: Number
},

'Ct11' : {
        prop: 'count11',
        type: Number
    },
'Ct11t' : {
        prop: 'count11_transferred',
        type: Number
},

'Ct12' : {
        prop: 'count12',
        type: Number
    },
'Ct12t' : {
        prop: 'count12_transferred',
        type: Number
},

'Ct13' : {
        prop: 'count13',
        type: Number
    },
'Ct13t' : {
        prop: 'count13_transferred',
        type: Number
},

'Ct14' : {
        prop: 'count14',
        type: Number
    },
'Ct14t' : {
        prop: 'count14_transferred',
        type: Number
},

'Ct15' : {
        prop: 'count15',
        type: Number
    },
'Ct15t' : {
        prop: 'count15_transferred',
        type: Number
},

'Ct16' : {
        prop: 'count16',
        type: Number
    },
'Ct16t' : {
        prop: 'count16_transferred',
        type: Number
},

'Ct17' : {
        prop: 'count17',
        type: Number
    },
'Ct17t' : {
        prop: 'count17_transferred',
        type: Number
},

'Ct18' : {
        prop: 'count18',
        type: Number
    },
'Ct18t' : {
        prop: 'count18_transferred',
        type: Number
},

'Ct19' : {
        prop: 'count19',
        type: Number
    },
'Ct19t' : {
        prop: 'count19_transferred',
        type: Number
},

'Ct20' : {
        prop: 'count20',
        type: Number
    },
'Ct20t' : {
        prop: 'count20_transferred',
        type: Number
},

'Ct21' : {
        prop: 'count21',
        type: Number
    },
'Ct21t' : {
        prop: 'count21_transferred',
        type: Number
},

'Ct22' : {
        prop: 'count22',
        type: Number
    },
'Quota' : {
        prop: 'quota',
        type: Number
}
};



contract("ElectionController", async (accounts) => {
    const officialVotes = 305556;
    const districtsNo = 13;
    const parties = ['PL','PN','AD','Ind','PA','AL'];

    var electionController;
    var districtFactory;
    var voteTokenFactory;
    var candidates;
    var candidateAddresses;
    var addressToName;
    var addressToParty;
    var _name;
    var _voteStart;
    var _voteEnd;
    //var districtsNo;
    var numberOfPartiesContesting;
    var voteTokenIDs;
    var DistrictSheetRows;

    before(async () => {
 
    
    async function createVoteToken(electionController, districtNo,x){
        for(let i = 0; i<x; i++){
            let id = web3.utils.randomHex(256);
            await electionController.mintVote(id,districtNo,0); 
            voteTokenIDs[districtNo-1].push(id);
            console.log(districtNo + '\t' + i + ': ' + id + '\n');
        }
    }

    
    candidates = JSON.parse(fs.readFileSync(__dirname+'/candidates.json').toString());
    candidateAddresses = JSON.parse(fs.readFileSync(__dirname+'/candidateAddresses.json').toString());
    voteTokenIDs = JSON.parse(fs.readFileSync(__dirname+'/voteTokenIDs.json').toString());
    addressToName = JSON.parse(fs.readFileSync(__dirname+'/addressToName.json').toString());
    addressToParty = JSON.parse(fs.readFileSync(__dirname+'/addressToParty.json').toString());
    
    if(candidates.length == 0 || candidateAddresses.length == 0 || voteTokenIDs.length == 0 || addressToName.length == 0 || addressToParty.length == 0){

        numberOfPartiesContesting = parties.length;
        districtFactory = await DistrictFactory.new();
        voteTokenFactory = await VoteTokenFactory.new();
        candidates = [];
        candidateAddresses = [];
        voteTokenIDs = [];
        DistrictSheetRows = [];
        addressToName = {};
        addressToParty = {};
        _name = "TEST";
        _voteStart = 0;
        _voteEnd = Date.now() + 999999999;

        electionController = await ElectionController.new(districtsNo,districtFactory.address,voteTokenFactory.address);
        var numberOfVotesEachDistrict = [];

        for(let i = 1; i<=districtsNo; i++){
            var numberOfVotesInThisDistrict = 0;
            candidates.push([]);
            candidateAddresses.push([]);
            voteTokenIDs.push([]);


            
            let {rows,errors} = await readXlsxFile(__dirname + '/d' + i +'.xlsx',{schema});
            DistrictSheetRows.push(rows);

            for(let j = 0; j<rows.length; j++){
                let row = rows[j];
                let _address= await web3.eth.accounts.create().address;

                //console.log(_address);
                addressToName[_address] = row.name;
                addressToParty[_address] = row.party;
                numberOfVotesInThisDistrict += row.count1;
                
                candidateAddresses[i-1].push(_address);
                
                candidates[i-1].push([
                    _address,
                    parties.indexOf(row.party), //Party
                    i, //District No
                    false, //elected
                    false, //eliminated
                    0
                ]);
            }
            
            numberOfVotesEachDistrict.push(numberOfVotesInThisDistrict);
            }

            await electionController.launchElection(_name,_voteStart,_voteEnd,numberOfPartiesContesting,candidates);
            fs.writeFileSync(__dirname+'/electionControllerAddress.json',JSON.stringify(electionController.address));
            fs.writeFileSync(__dirname+'/candidates.json',JSON.stringify(candidates));
            fs.writeFileSync(__dirname+'/candidateAddresses.json',JSON.stringify(candidateAddresses));
            fs.writeFileSync(__dirname+'/addressToName.json',JSON.stringify(addressToName));
            fs.writeFileSync(__dirname+'/addressToParty.json',JSON.stringify(addressToParty));

            for(let i = 0; i<numberOfVotesEachDistrict.length; i++){
                await createVoteToken(electionController,i+1,numberOfVotesEachDistrict[i]);
                fs.writeFileSync(__dirname+'/voteTokenIDs'+(i+1)+'.json',JSON.stringify([voteTokenIDs[i]]));
            }

            fs.writeFileSync(__dirname+'/voteTokenIDs.json',JSON.stringify(voteTokenIDs));

        }
        else{
            electionController = await ElectionController.at(JSON.parse(fs.readFileSync(__dirname+'/electionControllerAddress.json').toString()));
        }
    });

    it('The number of votes in the Controlling contract\'s balance should match the official recorded number of votes for this election.', async () => {
        
        
        let election = await electionController.elections(0);
        let voteToken = await VoteToken.at(election.voteToken);
        let balance = await voteToken.balanceOf(electionController.address);
        console.log( balance);
        
        assert.equal(officialVotes,balance);
    });
});