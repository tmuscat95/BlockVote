pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './VoteToken.sol';

contract VoteTokenFactory{
    function create(string memory _name, uint _voteStart, uint _voteEnd) public returns(VoteToken){
        return new VoteToken(_name,"",_voteStart,_voteEnd);
    }
}