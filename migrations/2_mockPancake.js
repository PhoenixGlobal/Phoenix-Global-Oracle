const mockpancake = artifacts.require("MockPancake");
const oracle = artifacts.require("HznAggregatorV2V3");
const oracleManager = artifacts.require("OracleManager");


module.exports = function (deployer,network,accounts) {
  // deployer.deploy(mockpancake).then(function(){
  //     return deployer.deploy(oracle,accounts[0],18,10,accounts[0],mockpancake.address,[0xc0eff7749b125444953ef89682201fb8c6a917cd,0xe9e7cea3dedca5984780bafc599bd69add087d56],1)
  // });

  deployer.deploy(oracle,accounts[0],18,10,accounts[0],'0xb5A967918279557571ebB17d5101eE356Cc8Fc03',['0xc0eff7749b125444953ef89682201fb8c6a917cd','0xe9e7cea3dedca5984780bafc599bd69add087d56'], '1000000000000000000')


  // deployer.deploy(oracleManager,'0x64aC4907B29aA25f4Df91356fAC4772F16A4803e', '0xF09f5E21F86692C614D2D7B47E3b9729DC1C436F', '0x64aC4907B29aA25f4Df91356fAC4772F16A4803e')


};
