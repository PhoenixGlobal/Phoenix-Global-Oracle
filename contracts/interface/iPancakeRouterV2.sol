pragma solidity ^0.5.16;

interface iPancakeRouterV2 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}