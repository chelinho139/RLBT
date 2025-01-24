// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ConstantRLBT.sol";
import "./mocks/MockOracle.sol";
import "./mocks/MockUSDC.sol";

contract ConstantRLBTTest is Test {
    using Math for uint256;

    ConstantRLBT public rlbt;
    MockOracle public oracle;
    MockUSDC public usdc;

    address user = vm.addr(1);
    address admin = vm.addr(2);

    uint256 lowerRedemptionPrice = 1e6; // 1 USDC per RLBT
    uint256 upperRedemptionPrice = 1.5e6; // 1.5 USDC per RLBT
    uint256 initialCollateral = 1_000e6; // 1,000 USDC
    uint256 initialSupply = 1_000; // 1,000 RLBT

    event Mint(address indexed minter, uint256 amount, uint256 collateralAdded);
    event Burn(address indexed burner, uint256 amount, uint256 collateralRemoved);

    function setUp() public {
        usdc = new MockUSDC();
        oracle = new MockOracle();

        vm.startPrank(admin);
        usdc.mint(admin, 1_000e6); // Mint 1 USDC to admin
        rlbt = new ConstantRLBT(
            address(usdc), 
            address(oracle), 
            initialCollateral,
            initialSupply,
            lowerRedemptionPrice, 
            upperRedemptionPrice
        );
        vm.stopPrank();
    }

    function test_mint_addsCollateralAndMintsTokens() public {
        uint256 mintAmount = 1_000; // Mint 1,000 RLBT
        uint256 mintCollateral = mintAmount * upperRedemptionPrice; // 1.5 USDC per RLBT

        // Mint USDC to user and approve RLBT
        usdc.mint(user, mintCollateral);
        vm.startPrank(user);
        usdc.approve(address(rlbt), mintCollateral);

        // Expect Mint event
        vm.expectEmit(true, true, true, true);
        emit Mint(user, mintAmount, mintCollateral);

        rlbt.mint(user, mintAmount);

        // Assertions
        assertEq(usdc.balanceOf(address(rlbt)), mintCollateral, "Contract should hold the collateral");
        assertEq(rlbt.balanceOf(user), mintAmount, "User should receive the minted RLBT");
        assertEq(rlbt.collateral(), initialCollateral + mintCollateral, "Collateral should update correctly");
        assertEq(rlbt.totalSupply(), initialSupply + mintAmount, "Total supply should update correctly");
        vm.stopPrank();
    }

    function test_mint_revertsIfInsufficientCollateral() public {
        uint256 mintAmount = 100 ether;
        uint256 requiredCollateral = mintAmount * upperRedemptionPrice / 1e6; // 1.5 USDC per RLBT

        vm.prank(user);
        vm.expectRevert("Insufficient USDC balance");
        rlbt.mint(user, mintAmount);
    }

    function test_burn_removesCollateralAndBurnsTokens() public {
        // Given
        uint256 burnAmount = 1; // Burn 1 RLBT
        uint256 burnCollateral = burnAmount * lowerRedemptionPrice; // Burn collateral (1.0 USDC/RLBT)

        vm.startPrank(user);
        // Mint burn amount tokens to user
        uint256 mintCollateral = burnAmount * upperRedemptionPrice; // Mint collateral (1.5 USDC/RLBT)
        usdc.approve(address(rlbt), mintCollateral);
        usdc.mint(user, mintCollateral);
        rlbt.mint(user, burnAmount);

        uint256 rlbtPreCollateral = initialCollateral + mintCollateral;

        // Expect Burn event
        vm.expectEmit(true, true, true, true);
        emit Burn(user, burnAmount, burnCollateral);

        // When
        rlbt.burn(user, burnAmount);

        // Assertions
        assertEq(rlbt.balanceOf(user), 0, "User should have zero RLBT");
        assertEq(usdc.balanceOf(user), burnCollateral, "User should receive burned collateral");
        assertEq(rlbt.collateral(), rlbtPreCollateral - burnCollateral, "Collateral should update correctly");
        vm.stopPrank();
    }

    function test_burn_revertsIfInsufficientCollateralInContract() public {
        // Given
        uint256 burnAmount = 100000; // Burn 100000 RLBT
        uint256 burnCollateral = burnAmount * lowerRedemptionPrice; // Burn collateral (1.0 USDC/RLBT)
        assert(burnCollateral > initialCollateral);
        
        // When
        vm.expectRevert("Insufficient contract collateral");
        rlbt.burn(user, burnAmount);
        vm.stopPrank();
    }

    function test_burn_revertsIfInsiffucientTokenSupply() public {
        // Given
        uint256 mintAmount = 1_000; // Mint 1,000 RLBT
        uint256 mintCollateral = mintAmount * upperRedemptionPrice; // Mint collateral (1.5 USDC/RLBT)
        usdc.mint(user, mintCollateral);
        vm.startPrank(user);        
        usdc.approve(address(rlbt), mintCollateral);

        // Mint 1,000 RLBT at 1.5 USDC/RLBT
        rlbt.mint(user, mintAmount);

        // Try to remove total supply + 1 RLBT
        uint256 burnAmount = rlbt.totalSupply() + 1;

        // When
        vm.expectRevert("Insufficient RLBT token supply");
        rlbt.burn(user, burnAmount);
    }

    function test_fetchCurrentPrice_returnsOraclePrice() public {
        uint256 mockPrice = 1.2e6; // 1.2 USDC per RLBT
        oracle.setRLBTPrice(mockPrice);

        uint256 fetchedPrice = rlbt.fetchCurrentPrice();
        assertEq(fetchedPrice, mockPrice, "Fetched price should match oracle price");
    }
} 
