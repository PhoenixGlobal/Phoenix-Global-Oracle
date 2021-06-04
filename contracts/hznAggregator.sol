pragma solidity ^0.5.16;

import "@chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorV2V3Interface.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./interface/iPancakeRouterV2.sol";

// interface iPancakeRouterV2 {
//     function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
// }

contract HznAggregatorV2V3 is AggregatorV2V3Interface {
    using SafeMath for uint;
    // using SafeDecimalMath for uint; 

    uint public roundID = 0;
    uint public keyDecimals = 0;
    //here we simplify the window size as how many rounds we use to calculate th TWAP
    uint public windowSize = 0; 

    struct Entry {
        uint roundID;
        uint answer;
        uint originAnswer;
        uint startedAt;
        uint updatedAt;
        uint answeredInRound;
        uint priceCumulative;
    }

    mapping(uint => Entry) public entries;
    address owner;
    address operator;

    //pancakeRouterV2 contracat addresss
    address pancakeRouterV2Addr;

    //pancake swap path 
    //should be [hzn,wbnb,busd(or other stable coin)]
    address[] path;

    //swap amount should be 1 hzn = 1e18 
    uint amountIn;

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    event AnswerUpdated(uint256 indexed answer, uint256 timestamp);

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    modifier onlyOperator {
        _onlyOperator();
        _;
    }

    function _onlyOperator() private view {
        require(msg.sender == operator, "Only the contract owner may perform this action");
    }

    constructor(address _owner,
                uint _decimals,
                uint _windowSize,
                address _operator,
                address _pancakeV2,
                address[] memory _path,
                uint _amountIn) public {
        owner = _owner;
        keyDecimals = _decimals;
        windowSize = _windowSize;
        operator = _operator;
        pancakeRouterV2Addr = _pancakeV2;
        path = _path;
        amountIn = _amountIn;
    }

    //========  setters ================//
    function setDecimals(uint _decimals) external onlyOwner {
        keyDecimals = _decimals;
    }

    function setWindowSize(uint _windowSize)external onlyOwner  {
        windowSize = _windowSize;
    }

    function setAmountsOut(uint _amountIn,address[] calldata _path) external onlyOwner {
        amountIn = _amountIn;
        path = _path;
    }

    //========== add price================//
    /***
    this is for decentralized mode,
    when triggered by offline server , will query from pancake router v2 to get hzn busd price
    for mainnet
    https://bscscan.com/address/0x10ed43c718714eb63d5aa57b78b54704e256024e#readContract
    6. getAmountsOut

    amountIn: 1000000000000000000
    //means 1 hzn

    path:[0xc0eff7749b125444953ef89682201fb8c6a917cd,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,0xe9e7cea3dedca5984780bafc599bd69add087d56]
    //means :hzn -> wbnb -> busd

    output:
    amounts   uint256[] :  100000000000000000000   //1 hzn
    131032688024315468                             //0.00131 bnb
    72233046540554662116                           //0.7223 BUSD   
     */
    function updateLatestAnswer() external onlyOperator {

        //todo get answer from pancake smart contract
        iPancakeRouterV2 ip = iPancakeRouterV2(pancakeRouterV2Addr);
        uint[] memory latest = ip.getAmountsOut(amountIn, path); 
        uint answer = latest[latest.length - 1];

        
        if (entries[0].updatedAt > 0 ){
            roundID++;
        }

        entries[roundID] = calculateTWAP(roundID,answer,now);
        emit AnswerUpdated(answer,now);
    }

    function setLatestAnswer(uint answer) external onlyOperator {
        if (roundID > 0){
            roundID++;
        }
        entries[roundID] = calculateTWAP(roundID,answer,now);
        emit AnswerUpdated(answer,now);
    }

    function setPancakeRouterV2Addr(address _pancakeV2) external onlyOwner() {
        pancakeRouterV2Addr = _pancakeV2;
    }


    //====================interface ==================================
    function latestAnswer() external view returns (int256) {
        Entry memory entry = entries[roundID];
        return int256(entry.answer);
    }

    function latestTimestamp() external view returns (uint256){
        Entry memory entry = entries[roundID];
        return entry.updatedAt;
    }



    function latestRoundData()
        external
        view
        returns (
           uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return getRoundData(uint80(latestRound()));
    }

    function latestRound() public view returns (uint256) {
        return roundID;
    }

    function decimals() external view returns (uint8) {
        return uint8(keyDecimals);
    }

    function description() external view returns (string memory){
        return "hzn";
    }

    function version() external view returns (uint256){
        return 1;
    }

    function getAnswer(uint256 _roundId) external view returns (int256) {
        Entry memory entry = entries[_roundId];
        return int256(entry.answer);
    }

    function getTimestamp(uint256 _roundId) external view returns (uint256) {
        Entry memory entry = entries[_roundId];
        return entry.updatedAt;
    }

    function getRoundData(uint80 _roundId)
        public
        view
        returns (
           uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        Entry memory entry = entries[_roundId];
        // Emulate a Chainlink aggregator
        require(entry.updatedAt > 0, "No data present");
        return (uint80(entry.roundID), int256(entry.answer), entry.startedAt, entry.updatedAt, uint80(entry.answeredInRound));
    }


    function calculateTWAP(uint currentRoundId,uint answer,uint timestamp) internal view returns(Entry memory) {
        if (currentRoundId == 0 ){
            return  Entry({
                roundID: currentRoundId,
                answer: answer,
                originAnswer: answer,
                startedAt: timestamp,
                updatedAt: timestamp,
                answeredInRound: currentRoundId,
                priceCumulative: 0
            });
        }
        uint firstIdx = 0;
        if (windowSize >= currentRoundId) {
            firstIdx = 0;
        }else{
            firstIdx = currentRoundId - windowSize + 1;
        }
        Entry memory first = entries[firstIdx];
        Entry memory last = entries[currentRoundId - 1];

        if (first.roundID == last.roundID){
            return  Entry({
                roundID: currentRoundId,
                answer: answer,
                originAnswer: answer,
                startedAt: timestamp,
                updatedAt: timestamp,
                answeredInRound: currentRoundId,
                priceCumulative: last.priceCumulative.add(answer.mul(timestamp.sub(first.updatedAt)))
            }); 
        }

        uint current_priceCumulative = last.priceCumulative.add(answer.mul(timestamp.sub(last.updatedAt)));
        uint current_answer = (current_priceCumulative.sub(first.priceCumulative)).div(timestamp.sub(first.updatedAt));
        return Entry({
            roundID: currentRoundId,
            answer: current_answer,
            originAnswer: answer,
            startedAt: timestamp,
            updatedAt: timestamp,
            answeredInRound: currentRoundId,
            priceCumulative: current_priceCumulative
        });
        
    }   
}
