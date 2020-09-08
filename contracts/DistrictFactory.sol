pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./District.sol";

contract DistrictFactory{

    function create(uint8 _districtNumber, Shared.Candidate[] memory _candidates) public returns(District) {
        District d = new District(_districtNumber, _candidates);
        d.transferOwnership(msg.sender);
        return d;
    }
}