// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Raffle
 * @author eason
 * @notice A simple raffle contract
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is
    VRFConsumerBaseV2Plus,
    AutomationCompatibleInterface,
    AccessControl,
    Initializable
{
    error Raffle_UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );
    error Raffle_NotEnoughETHSent();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    bytes32 public constant MANAGE_ROLE = keccak256("MANAGE_ROLE");

    event EnteredRaffle(
        address indexed player,
        uint256 tokenId,
        uint256 amount
    );
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(
        address indexed winner,
        uint256 amount
    );

    uint16 private constant REQUESTION_CONFIRMATIONS = 3;
    uint32 private constant NEW_WORDS = 1;

    uint256 private i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;


    struct Order {
        address player;
        uint256 amount;
        uint256 token_id; //0 -> ETH, 1 -> USDT
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    struct Token {
        uint256 token_id; // currencyID // 0 ETH, 1 USDT, 2 USDC
        address token_address; // currency address
        uint256 min_bet_amount; // bet min
        uint256 max_bet_amount; // bet max
    }

    address payable[] private s_players;
    Order[] private orders;

    uint256 private s_lastTimeStamp;
    Order private s_recentWinner;
    RaffleState private s_raffleState;



    mapping(uint256 => RequestStatus) public s_requests;
    // mapping(uint256 => Order) public orderInfo;
    mapping(uint256 => Token) public tokens;

    constructor(
        uint256 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(SERVER_ROLE, msg.sender);
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function initialize(uint256 entranceFee) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(SERVER_ROLE, msg.sender);
        i_entranceFee = entranceFee;
    }

    function adminSetEnv(uint256 fee_percentage) public onlyRole(ADMIN_ROLE) {
        i_entranceFee = fee_percentage;
    }

    function adminSetToken(
        uint256 token_id,
        address token_address,
        uint256 min_bet_amount,
        uint256 max_bet_amount
    ) public onlyRole(ADMIN_ROLE) {
        tokens[token_id] = Token(
            token_id,
            token_address,
            min_bet_amount,
            max_bet_amount
        );
    }

    function enterRaffle(
        uint256 token_id, // 0 ETH, 1 USDT, 2 USDC
        uint256 amount
    ) public payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }
        // 检查金额
        uint256 amount_;
        if (token_id == 0) {
            amount_ = msg.value;
        } else {
            amount_ = amount;
        }

        // check
        if (!_checkAmount(token_id, amount_)) {
            revert Raffle_NotEnoughETHSent();
        }

        // transfer
        if (token_id > 0) {
            Token memory t = tokens[token_id];

            IERC20(t.token_address).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        // s_players.push(payable(msg.sender));
        Order memory o = Order({
            player: payable(msg.sender),
            amount: amount,
            token_id: token_id
        });
        orders.push(o);
        
        emit EnteredRaffle(msg.sender, token_id, amount);
    }

    // pickwinner
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(
                address(this).balance,
                orders.length,
                uint256(s_raffleState)
            );
        }
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert("Not Enough Time Passed!");
        }
        s_raffleState = RaffleState.CALCULATING;
        // vrf
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUESTION_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NEW_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * Chainlink VRF:  get Random words
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        if (!s_requests[_requestId].exists) {
            revert("request not found");
        }
        uint256 indexOfWinner = _randomWords[0] % orders.length;
        Order memory winner = orders[indexOfWinner];
        s_recentWinner = winner;

        // s_players = new address payable[](0);
        delete orders;
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner.player, winner.amount * 2);

        Token memory t = tokens[winner.token_id];
        // Transfer ERC20 tokens
        if (winner.token_id == 1 || winner.token_id == 2) {
            bool tokenSuccess = IERC20(t.token_address).transfer(winner.player, winner.amount * 2 - i_entranceFee);
            if (!tokenSuccess) {
                revert Raffle_TransferFailed();
            }
        } else if (winner.token_id == 0) {
            (bool success, ) = winner.player.call{value: winner.amount * 2 - i_entranceFee}("");
            if (!success) {
                revert Raffle_TransferFailed();
            }
        }
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function _checkAmount(
        uint256 tokenId_,
        uint256 amount_
    ) private view returns (bool) {
        Token memory t = tokens[tokenId_];
        if (t.max_bet_amount < amount_) {
            return false;
        } else if (t.min_bet_amount > amount_) {
            return false;
        }
        return true;
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
