pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './VoteToken.sol';

contract VoteTokenFactory{

    constructor() public{

    }

    function create(string calldata _name, uint _voteStart, uint _voteEnd) external returns(VoteToken){
        VoteToken t = new VoteToken(_name,"",_voteStart,_voteEnd);
        t.transferOwnership(msg.sender);
        return t;
    }
}