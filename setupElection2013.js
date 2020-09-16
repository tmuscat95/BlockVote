async function main(){
    const readXlsxFile = require('read-excel-file/node');
    const Schema = require(__dirname + '/schema.js');
    const fs = require('fs');
    const Web3 = require('web3');
    var contract = require("@truffle/contract");
    
    var provider = new Web3.providers.HttpProvider("HTTP://127.0.0.1:7545");
    var web3 = new Web3(provider);
    const accounts = await web3.eth.getAccounts();
    //await web3.eth.personal.unlockAccount(accounts[0],password="83ae34a8f77d9fcb8d979486f563ea031b002d6167cf4f22239ea1a52258edb0",99999999);

    path = __dirname + "/client/src/contracts/";
    

    const ElectionControllerJSON = require(path + "ElectionController.json");
    const DistrictFactoryJSON = require(path + "DistrictFactory.json");
    const VoteTokenFactoryJSON = require(path + "VoteTokenFactory.json");
    const DistrictJSON = require(path + "District.json");
    const VoteTokenJSON = require(path + "VoteToken.json");

    var ElectionController = contract(ElectionControllerJSON);
    var DistrictFactory = contract(DistrictFactoryJSON);
    var VoteTokenFactory = contract(VoteTokenFactoryJSON);
    var District = contract(DistrictJSON);
    var VoteToken = contract(VoteTokenJSON);

    ElectionController.setProvider(provider);
    DistrictFactory.setProvider(provider);
    VoteTokenFactory.setProvider(provider);
    District.setProvider(provider);
    VoteToken.setProvider(provider);

    const districtsNo = 13;
    const parties = ['PL','PN','AD'];
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
    var numberOfPartiesContesting;
    var voteTokenIDs;
    var DistrictSheetRows;
    var electionControllerWeb3;

    async function createVoteToken(electionController, districtNo,x){
        for(let i = 0; i<x; i++){
            let id = web3.utils.randomHex(256);
            //await electionController.mintVote(id,districtNo,0);
            await electionControllerWeb3.methods.mintVote(id,districtNo,0).send({from:accounts[0],gas: 4712388, gasPrice: 20000000000});
            voteTokenIDs[districtNo-1].push(id);
            console.log(districtNo + '\t' + i + ': ' + id + '\n');
        }
    }

    numberOfPartiesContesting = parties.length;
    candidates = [];
    candidateAddresses = [];
    voteTokenIDs = [];
    DistrictSheetRows = [];
    addressToName = {};
    addressToParty = {};
    _name = "TEST";
    _voteStart = 0;
    _voteEnd = Date.now() + 999999999;

    VoteTokenFactory.defaults({from:accounts[0],gas: 4712388, gasPrice: 20000000000});
    voteTokenFactory =  await VoteTokenFactory.new();
    
    DistrictFactory.defaults({from:accounts[0],gas: 4712388, gasPrice: 20000000000});
    districtFactory =  await DistrictFactory.new();
    
    ElectionController.defaults({from:accounts[0],gas: 4712388, gasPrice: 20000000000});
    electionController = await ElectionController.new(districtsNo,districtFactory.address,voteTokenFactory.address,{from: accounts[0]});
    //electionController =  await ElectionController.at('0xDCA50a869D1dFe6C4f5f7eF88583e22C1E822CD7');
    var numberOfVotesEachDistrict = [];

    for(let i = 1; i<=districtsNo; i++){
        var numberOfVotesInThisDistrict = 0;
        candidates.push([]);
        candidateAddresses.push([]);
        voteTokenIDs.push([]);


        let schema = Schema.schema;
        let {rows,errors} = await readXlsxFile(__dirname + '/test/d' + i +'.xlsx',{schema});
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

    //await electionController.launchElection(_name,_voteStart,_voteEnd,numberOfPartiesContesting,candidates,{from:accounts[0],gas: 4712388, gasPrice: 20000000000});
    electionControllerWeb3 = new web3.eth.Contract(jsonInterface = ElectionControllerJSON.abi,electionController.address);
    await electionControllerWeb3.methods.launchElection(_name,_voteStart,_voteEnd,numberOfPartiesContesting,candidates).send(options={from:accounts[0],gas: 4712388, gasPrice: 20000000000});

    for(let i = 0; i<numberOfVotesEachDistrict.length; i++){
        await createVoteToken(electionController,i+1,numberOfVotesEachDistrict[i]);
        
    }

    fs.writeSync(__dirname+'/test/candidates.json',JSON.stringify(candidates));
    fs.writeSync(__dirname+'/test/candidateAddresses.json',JSON.stringify(candidateAddresses));
    fs.writeSync(__dirname+'/test/voteTokenIDs.json',JSON.stringify(voteTokenIDs));
    fs.writeSync(__dirname+'/test/addressToName.json',JSON.stringify(addressToName));
    fs.writeSync(__dirname+'/test/addressToParty.json',JSON.stringify(addressToParty));

}

main();