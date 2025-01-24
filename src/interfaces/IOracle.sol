// TODO: Implement the IOracle interface
//       Either get the price from a LP (ie Uniswap) or an oracle (ie Chainlink)
interface IOracle {
    function getRLBTPrice() external view returns (uint256); // Returns RLBT/USDC price in 18 decimals
}
