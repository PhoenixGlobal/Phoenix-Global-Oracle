pragma solidity ^0.5.16;

import "./interface/iPancakeRouterV2.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
contract MockPancake is iPancakeRouterV2 {
    using SafeMath for uint;

    uint baseprice = 10 ** 16; //0.01 USD
    uint256[] mockAnswers = [70 ,71 , 75 ,80 ,65 ,50,100,150,89,90,105];

    constructor() public {
    }
    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts){
        uint idx = now % mockAnswers.length;
         uint[] memory res = new uint[](path.length);
         res[0] = amountIn;
         res[path.length - 1] = mockAnswers[idx] * baseprice;
        return res;
    }

}