pragma solidity ^0.5.16;

interface iOracleManager {
    //====admin functions====//
    function setPrice(address tokenAddr,uint256 price,uint period) external returns (bool);
    function setFeeToken(address tokenAddr) external returns(bool);
    function setUserAddressValid(address userAddr,bool valid) external returns(bool);
    function addWhitelist(address userAddr,bool valid) external returns(bool);
    function setFeeCollector(address feecollector)external returns(bool);

    //====view ====//
    function isAddressValid(address userAddr) external view returns(bool);

    //====mutable===//
    function charge(address foraddr,uint amount) external returns(bool);

}