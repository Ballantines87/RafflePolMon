/*

Contract elements should be laid out in the following order:
Pragma statements
Import statements
Events
Errors
Interfaces
Libraries
Contracts

Inside each contract, library or interface, use the following order:
Type declarations
State variables
Events
Errors
Modifiers
Functions

Functions should be grouped according to their visibility and ordered:
constructor
receive function (if exists)
fallback function (if exists)
external
public
internal
private
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

/**
 * @title That's a sample Lottery Raffle contract
 * @author Paolo Montecchiani
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRF v2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* State variables */
    uint256 private immutable i_entranceFee;
    /// @dev the duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /* Events */
    event RaffleEntered(address indexed player);

    /* Errors */
    error Raffle_NotEnoughETHForEntranceFee();
    error Raffle_NotEnoughTimePassedToPickWinner();

    constructor(uint256 _entranceFee, uint256 _interval) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent to pay the entrance fee")

        // require(
        //     msg.value >= i_entranceFee,
        //     Raffle_NotEnoughETHForEntranceFee()
        // );

        if (msg.value >= i_entranceFee) {
            revert Raffle_NotEnoughETHForEntranceFee();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Be automatically called
    function pickWinner() external {
        // check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert Raffle_NotEnoughTimePassedToPickWinner();
        }

        // get our random number from Chainlink VRF 2.5
        // 1. Request RNG
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        // 2 Get RNG
    }

    /* Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
