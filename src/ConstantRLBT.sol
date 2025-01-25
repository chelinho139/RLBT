// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IOracle } from "./interfaces/IOracle.sol";

contract ConstantRLBT is ERC20 {
    using Math for uint256;

    IERC20 public immutable usdc; // USDC token contract
    IOracle public immutable oracle; // Oracle contract for RLBT/USDC price
    uint256 public collateral; // Collateral balance in USDC
    uint256 public upperRedemptionPrice; // R_U (e.g., 1.5 USDC per RLBT)
    uint256 public lowerRedemptionPrice; // R_L (e.g., 1.0 USDC per RLBT)

    // Events
    event Mint(address indexed minter, uint256 amount, uint256 collateralAdded);
    event Burn(address indexed burner, uint256 amount, uint256 collateralRemoved);

    constructor(
        address _usdcAddress,
        address _oracleAddress,
        uint256 _initialCollateral,
        uint256 _initialSupply,
        uint256 _lowerRedemptionPrice,
        uint256 _upperRedemptionPrice
    ) ERC20("RLBT", "RLBT") {
        require(_usdcAddress != address(0), "Invalid USDC address");
        require(_oracleAddress != address(0), "Invalid Oracle address");
        require(_initialCollateral > 0, "Invalid initial collateral");
        require(_initialSupply > 0, "Invalid initial supply");

        usdc = IERC20(_usdcAddress);
        oracle = IOracle(_oracleAddress);

        // Init collateral and mint initial supply
        _mint(msg.sender, _initialSupply);
        collateral = _initialCollateral;
        emit Mint(msg.sender, _initialSupply, _initialCollateral);

        if (_lowerRedemptionPrice > 0) {
            require(_lowerRedemptionPrice < _upperRedemptionPrice, "Invalid redemption prices");
            lowerRedemptionPrice = _lowerRedemptionPrice;
            upperRedemptionPrice = _upperRedemptionPrice;
        }
    }

    function _update(address from, address to, uint256 value) internal override {
        // Check that from and to are not the zero address
        require(from != address(0) || to != address(0), "ERC20: _update from/to the zero address");

        if (from == address(0)) {
            // Mint
            _customMint(to, value);
        }

        if (to == address(0)) {
            // Burn
            _customBurn(from, value);
        }

        // Update will handle mint/burn/transfer internally 
        // (increase/reduce supply for mint/burn and update balances)
        super._update(from, to, value);
    }
    
    /**
     * @dev Mints new tokens by depositing USDC as collateral.
     */
    function _customMint(address to, uint256 value) internal {
        (bool result, uint256 collateralRequired) = value.tryMul(upperRedemptionPrice); // Collateral required in USDC
        if (!result) {
            // TODO: Suitable error message
            revert("Mint amount too high");
        }

        require(usdc.balanceOf(to) >= collateralRequired, "Insufficient USDC balance");
        // TODO: This requires a prior approval. See https://eips.ethereum.org/EIPS/eip-2612 to avoid it (permit)
        require(usdc.transferFrom(to, address(this), collateralRequired), "USDC transfer failed");
        collateral += collateralRequired;

        emit Mint(to, value, collateralRequired);
    }

    /**
     * @dev Burns tokens and withdraws the corresponding collateral in USDC.
     */
    function _customBurn(address from, uint256 value) internal {
        (bool result, uint256 collateralToReturn) = value.tryMul(lowerRedemptionPrice); // Collateral to return in USDC
        if (!result) {
            // TODO: Suitable error message
            revert("Burn amount too high");
        }
        require(collateral >= collateralToReturn, "Insufficient contract collateral");
        require(totalSupply() >= value, "Insufficient RLBT token supply");

        require(usdc.balanceOf(address(this)) >= collateralToReturn, "Insufficient USDC balance");
        require(usdc.transfer(from, collateralToReturn), "USDC transfer failed");
        collateral -= collateralToReturn;

        emit Burn(from, value, collateralToReturn);
    }

    /**
     * @dev Fetches the current RLBT/USDC price from the Oracle.
     */
    function fetchCurrentPrice() external view returns (uint256) {
        return oracle.getRLBTPrice();
    }

    function mint(address account, uint256 value) external {
        _mint(account, value);
    }

    function burn(address account, uint256 value) external {
        _burn(account, value);
    }
}
