// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    event RaffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 _entranceFee;
    uint256 _interval;
    address _vrfCoordinatoraddress;
    bytes32 _gasLane;
    uint256 _subscriptionId;
    uint32 _callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffleContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        _entranceFee = config.entranceFee;
        _interval = config.interval;
        _vrfCoordinatoraddress = config.vrfCoordinatoraddress;
        _gasLane = config.gasLane;
        _subscriptionId = config.subscriptionId;
        _callbackGasLimit = config.callbackGasLimit;
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /*//////////////////////////////////////////////////////////////
                            ENTERRAFFLE
    //////////////////////////////////////////////////////////////*/

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.startPrank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        // Act --- // Assert
        vm.expectRevert(Raffle.Raffle_NotEnoughETHForEntranceFee.selector);
        raffle.enterRaffle();
        vm.stopPrank();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        // Act
        raffle.enterRaffle{value: _entranceFee}();
        vm.stopPrank();
        // Assert
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function testREnteringRaffleEmitsEvent() public {
        // Arrange
        vm.startPrank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // Assert
        raffle.enterRaffle{value: _entranceFee}();
        vm.stopPrank();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.startPrank(PLAYER);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        // Act
        raffle.enterRaffle{value: _entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Assert
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        raffle.enterRaffle{value: _entranceFee}();
        vm.stopPrank();
    }
}
