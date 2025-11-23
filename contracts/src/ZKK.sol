// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

/**
 * @title ZKK - ZakoKen Omnichain Fungible Token
 * @notice Dynamic fundraising stablecoin with compose message support
 * @dev Extends LayerZero OFT standard with off-chain transaction metadata
 */
contract ZKK is OFT {

    // ============ Events ============

    event TokensMinted(
        address indexed recipient,
        uint256 amount,
        bytes32 indexed txHash,
        bytes32 indexed projectId,
        uint256 greedIndex,
        uint256 timestamp
    );

    event ComposeMessageReceived(
        bytes32 indexed guid,
        address indexed from,
        bytes composeMsg
    );

    // ============ Errors ============

    error InvalidAmount();
    error InvalidRecipient();
    error GreedLimitExceeded();

    // ============ State Variables ============

    /// @notice Project identifier for this token
    bytes32 public projectId;

    /// @notice Base greed multiplier (in basis points, 10000 = 1x)
    uint256 public constant BASE_GREED_MULTIPLIER = 10000;

    /// @notice Maximum greed multiplier (20000 = 2x)
    uint256 public constant MAX_GREED_MULTIPLIER = 20000;

    /// @notice Mapping of user addresses to their last mint timestamp
    mapping(address => uint256) public lastMintTime;

    /// @notice Mapping of user addresses to their total minted amount
    mapping(address => uint256) public totalMinted;

    // ============ Constructor ============

    /**
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _lzEndpoint LayerZero endpoint address
     * @param _owner Contract owner address
     * @param _projectId Unique project identifier
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _owner,
        bytes32 _projectId
    ) OFT(_name, _symbol, _lzEndpoint, _owner) {
        projectId = _projectId;
    }

    // ============ External Functions ============

    /**
     * @notice Mint tokens with compose message for off-chain transaction metadata
     * @param to Recipient address
     * @param amount Base amount to mint (before greed multiplier)
     * @param txHash Off-chain transaction hash
     * @param _projectId Project identifier (must match contract's projectId)
     */
    function mintWithCompose(
        address to,
        uint256 amount,
        bytes32 txHash,
        bytes32 _projectId
    ) external onlyOwner {
        if (to == address(0)) revert InvalidRecipient();
        if (amount == 0) revert InvalidAmount();
        if (_projectId != projectId) revert InvalidAmount();

        // Apply greed model
        uint256 greedIndex = applyGreedModel(to, amount);
        uint256 finalAmount = (amount * greedIndex) / BASE_GREED_MULTIPLIER;

        // Update user state
        lastMintTime[to] = block.timestamp;
        totalMinted[to] += finalAmount;

        // Mint tokens
        _mint(to, finalAmount);

        emit TokensMinted(
            to,
            finalAmount,
            txHash,
            _projectId,
            greedIndex,
            block.timestamp
        );
    }

    /**
     * @notice Handle composed messages from LayerZero
     * @param _from Source chain sender address
     * @param _guid Message GUID
     * @param _message Composed message data
     */
    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address, // _executor - unused
        bytes calldata // _extraData - unused
    ) external payable {
        // Only allow calls from the endpoint
        require(
            msg.sender == address(endpoint),
            "OFT: only endpoint can call"
        );

        // Verify message length
        require(_message.length >= 180, "Invalid message length");

        // Decode the compose message
        // Message format: [txHash(32)][timestamp(32)][amount(32)][recipient(20)][projectId(32)][greedIndex(32)]
        bytes32 txHash = bytes32(_message[0:32]);
        uint256 timestamp = uint256(bytes32(_message[32:64]));
        uint256 amount = uint256(bytes32(_message[64:96]));
        address recipient = address(bytes20(_message[96:116]));
        bytes32 msgProjectId = bytes32(_message[116:148]);
        uint256 greedIndex = uint256(bytes32(_message[148:180]));

        emit ComposeMessageReceived(_guid, _from, _message);

        // Store metadata on-chain for transparency
        emit TokensMinted(
            recipient,
            amount,
            txHash,
            msgProjectId,
            greedIndex,
            timestamp
        );
    }

    // ============ Internal Functions ============

    /**
     * @notice Apply simplified greed model for demo
     * @dev Production version would include velocity, time decay, and concentration factors
     * @param user User address
     * @param baseAmount Base amount before multiplier
     * @return greedIndex Greed multiplier in basis points
     */
    function applyGreedModel(
        address user,
        uint256 baseAmount
    ) internal view returns (uint256 greedIndex) {
        // Simplified greed model for hackathon demo
        // In production, this would consider:
        // - Transaction velocity (rapid successive mints = higher greed)
        // - Time decay (older users get better rates)
        // - Token concentration (whales pay more)

        uint256 timeSinceLastMint = block.timestamp - lastMintTime[user];
        uint256 userTotal = totalMinted[user];

        // Base multiplier: 1x (10000 basis points)
        greedIndex = BASE_GREED_MULTIPLIER;

        // Penalty for rapid minting (< 1 hour): +10%
        if (timeSinceLastMint < 1 hours && lastMintTime[user] != 0) {
            greedIndex += 1000; // +10%
        }

        // Penalty for large holders (> 10000 tokens): +20%
        if (userTotal > 10000 * 1e18) {
            greedIndex += 2000; // +20%
        }

        // Penalty for large single transactions (> 1000 tokens): +15%
        if (baseAmount > 1000 * 1e18) {
            greedIndex += 1500; // +15%
        }

        // Cap at maximum greed multiplier
        if (greedIndex > MAX_GREED_MULTIPLIER) {
            greedIndex = MAX_GREED_MULTIPLIER;
        }

        return greedIndex;
    }
}
