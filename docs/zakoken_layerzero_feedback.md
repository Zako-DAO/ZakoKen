# ZakoKen - LayerZero Developer Feedback

**ETHGlobal Buenos Aires 2025 - Best Developer Feedback Submission ($750)**

---

## 1. Project Context

**Project**: ZakoKen - Dynamic Fundraising Stablecoin Protocol
**Use Case**: Omnichain fungible token with compose messages for off-chain transaction metadata
**Chains**: Ethereum Sepolia ↔ Base Sepolia
**Implementation**: OFT v2 with custom `lzCompose()` handler
**GitHub**: https://github.com/ZakoDAO/ZakoKen

---

## 2. What Worked Well ✅

**Strengths of LayerZero that impressed us:**

### 2.1 OFT Standard Clarity

The base `OFT.sol` contract is well-architected. Extending it was intuitive:

```solidity
// contracts/src/ZKK.sol
contract ZKK is OFT {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _owner,
        bytes32 _projectId
    ) OFT(_name, _symbol, _lzEndpoint, _owner) {
        projectId = _projectId;
    }
}
```

**Why this worked well:**
- Clear inheritance pattern
- Well-documented constructor parameters
- Minimal boilerplate required

### 2.2 Cross-Chain Messaging

Once configured, the `send()` function worked reliably. Testnet infrastructure (Sepolia ↔ Base Sepolia) was stable.

```typescript
// Example from our deployment script
const tx = await zkk.send(
  sendParam,
  { nativeFee, lzTokenFee },
  refundAddress
);
```

**Testnet performance:**
- Average cross-chain latency: ~2-5 minutes
- 100% delivery success rate in our testing
- No dropped messages

### 2.3 LayerZero Scan

The testnet explorer (https://testnet.layerzeroscan.com) is invaluable for tracking cross-chain transactions.

**What we loved:**
- Real-time message status tracking
- Clear visualization of cross-chain flow
- Transaction hash linking between chains
- Saved us hours of debugging

### 2.4 Endpoint Addresses

Having standardized testnet endpoints documented clearly was helpful:

```typescript
const LZ_ENDPOINTS = {
  sepolia: "0x6EDCE65403992e310A62460808c4b910D972f10f",
  baseSepolia: "0x6EDCE65403992e310A62460808c4b910D972f10f",
};
```

**Impact:** Reduced setup time from hours to minutes.

---

## 3. Critical Pain Points 🚨

### 3.1 Compose Message Documentation Gap (MAJOR ISSUE)

**Problem**: Implementing `lzCompose()` was by far the most challenging part of our LayerZero integration. The documentation on compose messages is severely lacking.

#### What we struggled with:

#### A. No Clear Examples

The official docs mention compose messages exist, but there are almost **zero complete code examples** showing:

1. How to encode a compose message when calling `send()`
2. What format the `_composeMsg` parameter expects
3. How to decode it in `lzCompose()`

**Time wasted**: 4+ hours reverse-engineering the expected format from the OFT source code and GitHub issues.

#### B. Message Format Ambiguity

Our final implementation uses manual byte slicing, but we had to guess this approach:

```solidity
// contracts/src/ZKK.sol:118-154
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
```

**Questions we had:**
- Is manual byte slicing the recommended approach?
- Should we use `abi.encode()` / `abi.decode()`?
- What's the performance difference?
- How do we handle variable-length data?

**Suggested fix**: Provide an official `OFTComposeCodec` library similar to `OFTMsgCodec` that handles encoding/decoding compose messages with type safety.

Example of what we wish existed:

```solidity
// Wishlist: @layerzerolabs/lz-evm-oapp-v2/contracts/libs/OFTComposeCodec.sol
library OFTComposeCodec {
    struct ComposeMessage {
        bytes32 txHash;
        uint256 timestamp;
        uint256 amount;
        address recipient;
        bytes32 projectId;
        uint256 greedIndex;
    }

    function encode(ComposeMessage memory msg) internal pure returns (bytes memory) {
        return abi.encode(
            msg.txHash,
            msg.timestamp,
            msg.amount,
            msg.recipient,
            msg.projectId,
            msg.greedIndex
        );
    }

    function decode(bytes calldata data) internal pure returns (ComposeMessage memory) {
        return abi.decode(data, (ComposeMessage));
    }
}
```

#### C. Gas Estimation for Compose

No guidance on how much gas to allocate for compose message execution.

**Our experience:**
- First attempt: `200,000` gas → **FAILED** ❌
- Second attempt: `300,000` gas → **SUCCESS** ✅
- Took 3 test transactions (and wasted testnet ETH) to figure this out

**Suggested fix**: Add a `estimateComposeGas(bytes memory composeMsg)` helper function to the SDK or provide gas estimation tables for common use cases.

Example:

```typescript
// Wishlist: @layerzerolabs/devtools
const gasEstimate = await lzEndpoint.estimateComposeGas(
  dstEid,
  composeMsg
);
console.log(`Estimated gas: ${gasEstimate}`);
```

#### What would help:

✅ A dedicated **"Compose Messages Guide"** page with:
- Full end-to-end example (simple use case like attaching metadata)
- Encoding/decoding patterns (manual vs abi.encode)
- Gas estimation guidelines
- Common pitfalls and error messages
- Best practices for different data types

✅ Official **`ComposeMessageCodec`** library in `@layerzerolabs/lz-evm-oapp-v2`

✅ **TypeScript SDK support** for compose message building

---

### 3.2 Local Testing Cross-Chain Functionality (MEDIUM ISSUE)

**Problem**: Testing cross-chain OFT behavior locally is extremely difficult.

#### Current situation:

We wanted to test our `lzCompose()` logic without deploying to testnet every time.

**Attempted approach:**

```solidity
// test/MockLZEndpoint.sol - Had to write this from scratch
contract MockLZEndpoint {
    // No official mock provided by LayerZero
    // Spent 2 hours writing a minimal mock that partially works

    mapping(uint32 => bytes32) public peers;

    function send(...) external payable {
        // Simplified mock - doesn't actually deliver messages
        emit MessageSent(...);
    }
}
```

**Problems:**
- The mock doesn't support compose message delivery properly
- Can't test the full message flow locally
- Still had to deploy to testnet for every iteration
- Each deployment cycle: 5-10 minutes
- Total iterations during development: ~15 times
- **Total time wasted**: ~2 hours waiting for testnet deployments

**What would help:**

✅ **Official Mock Contracts**: Provide `MockLayerZeroEndpoint.sol` and `MockLayerZeroMessagingLib.sol` in the SDK for local testing.

Example usage:

```solidity
// test/ZKK.t.sol (Foundry)
import {MockLayerZeroEndpoint} from "@layerzerolabs/test-helpers/MockLayerZeroEndpoint.sol";

contract ZKKTest is Test {
    MockLayerZeroEndpoint lzEndpoint;
    ZKK zkk;

    function setUp() public {
        lzEndpoint = new MockLayerZeroEndpoint();
        zkk = new ZKK("ZakoKen", "ZKK", address(lzEndpoint), owner, projectId);
    }

    function testComposeMessage() public {
        // Mock should deliver compose message locally
        zkk.send(...);
        // Compose message should be automatically delivered in same test
    }
}
```

✅ **Hardhat Plugin**: A `hardhat-layerzero` plugin that simulates cross-chain messaging in local tests:

```javascript
// hardhat.config.ts
import "@layerzerolabs/hardhat-layerzero";

const lz = await ethers.getLayerZeroSimulator();
await lz.connectChains(sepolia, baseSepolia);

// In test:
await sepoliaZKK.send(message, baseSepolia);
// Automatically triggers lzReceive on baseSepolia in same test
const balance = await baseSepoliaZKK.balanceOf(recipient);
```

✅ **Testing Guide**: Document best practices for testing OFT contracts with compose messages.

Topics to cover:
- Unit testing compose message encoding/decoding
- Integration testing cross-chain flows
- Mocking LayerZero endpoints
- Gas estimation testing

---

### 3.3 TypeScript SDK Type Safety Issues (MEDIUM ISSUE)

**Problem**: Using LayerZero SDK with modern TypeScript + ethers v6 has rough edges.

#### Specific issues:

#### A. Type Definitions Incomplete

```typescript
// contracts/scripts/configure-layerzero.ts
const zkk = await ethers.getContractAt("ZKK", address, signer);

// TypeScript doesn't know about setPeer(), peers(), send(), etc.
// Error: Property 'setPeer' does not exist on type 'Contract'

// Workaround we had to use:
const zkk = (await ethers.getContractAt("ZKK", address, signer)) as any;
// OR
interface IZKK {
  setPeer(eid: number, peer: string): Promise<TransactionResponse>;
  peers(eid: number): Promise<string>;
  // ... manually define all methods
}
const zkk = await ethers.getContractAt("ZKK", address, signer) as unknown as IZKK;
```

**Impact**: Loss of type safety, increased risk of runtime errors.

#### B. Ethers v6 Compatibility

```typescript
// package.json dependencies conflict
{
  "dependencies": {
    "ethers": "^6.15.0",  // Modern ethers
    "@layerzerolabs/lz-evm-oapp-v2": "^3.0.147",  // Uses ethers v5 types
  }
}
```

**Problems encountered:**
- Type mismatches between `@ethersproject/providers` (v5) and `ethers` (v6)
- Had to use `@ethersproject/` packages in some scripts
- Dependency conflicts during `pnpm install`

**Workaround:**

```json
{
  "pnpm": {
    "overrides": {
      "@ethersproject/providers": "npm:ethers@^6"
    }
  }
}
```

#### C. Missing Helper Functions

```typescript
// contracts/scripts/configure-layerzero.ts:74
// Had to manually figure out peer address encoding
const peerAddress = ethers.zeroPadValue(baseSepoliaZKK, 32);
await sepoliaContract.setPeer(CHAIN_IDS.baseSepolia, peerAddress);
```

**Questions we had:**
- Why 32 bytes? (Answer: LayerZero uses bytes32 for addresses)
- Do we need `zeroPadValue` or `zeroPadBytes`?
- Should we use `ethers.getBytes()` first?

**What we wish existed:**

```typescript
import { encodePeerAddress, decodePeerAddress } from '@layerzerolabs/devtools';

// Clean API:
const encoded = encodePeerAddress(remoteAddress);
await zkk.setPeer(remoteEid, encoded);

// Reverse:
const peerBytes = await zkk.peers(remoteEid);
const peerAddress = decodePeerAddress(peerBytes);
```

#### What would help:

✅ **Update SDK to full ethers v6 support** with proper type exports

✅ **Provide TypeScript utilities**:

```typescript
import {
  encodePeerAddress,
  decodePeerAddress,
  estimateSendFee,
  buildSendParam,
  buildComposeMsg
} from '@layerzerolabs/devtools';

// Type-safe SendParam builder
const sendParam = buildSendParam({
  destinationEid: EndpointId.BASE_SEPOLIA,
  recipient: recipientAddress,
  amount: parseEther("100"),
  composeMsg: buildComposeMsg({
    txHash: txHash,
    timestamp: Date.now(),
    metadata: { ... }
  })
});
```

✅ **Auto-generate TypeScript types from OFT contracts**

---

### 3.4 Debugging and Error Messages (LOW-MEDIUM ISSUE)

**Problem**: When cross-chain transactions fail, error messages are often cryptic.

#### Examples we encountered:

#### A. Failed Transaction with No Clear Reason

**Error message:**
```
Error: transaction reverted: OApp: invalid endpoint caller
```

**What we tried:**
1. Checked if LayerZero endpoint address is correct ✅
2. Checked if contract is deployed correctly ✅
3. Verified transaction parameters ✅
4. Still no idea what's wrong ❓

**Actual problem** (took 30 minutes to realize):
- We forgot to call `setPeer()` on the destination chain

**Suggested fix**: Better error messages in OApp base contract:

```solidity
// Current (OApp.sol)
require(msg.sender == address(endpoint), "OApp: invalid endpoint caller");

// Improved version:
require(msg.sender == address(endpoint), "OApp: only endpoint can call lzReceive");
require(peers[srcEid] != bytes32(0), "OApp: peer not set for source chain");
require(peers[srcEid] == sender, "OApp: invalid sender (expected peer address)");
```

#### B. LayerZero Scan Limited Details

**Issue**: When a compose message fails, LayerZero Scan shows "Message Delivered" but doesn't show if `lzCompose()` reverted.

**Our debugging process:**
1. Check LayerZero Scan: "✅ Message Delivered"
2. Check destination chain balance: No tokens received ❓
3. Go to destination chain block explorer
4. Find the transaction manually
5. See that `lzCompose()` reverted with "Invalid message length"

**Time wasted**: 20 minutes per failed compose message

**Suggested fix**: Add "Compose Status" column in LayerZero Scan showing:
- ✅ Compose Executed Successfully
- ❌ Compose Reverted (with error message)
- ⏸️ Compose Not Called (message had no compose data)

#### What would help:

✅ **Improve error messages** in base contracts (OApp, OFT, OFTCore)

✅ **Enhance LayerZero Scan** to show compose execution status

✅ **Provide a "Common Errors & Solutions" troubleshooting page**

Example troubleshooting guide content:

| Error | Cause | Solution |
|-------|-------|----------|
| "OApp: invalid endpoint caller" | `msg.sender` is not LayerZero endpoint | Check that only endpoint calls `_lzReceive()` |
| "OApp: invalid peer" | Peer not set for source chain | Call `setPeer(srcEid, peerAddress)` |
| "OFT: slippage" | Received amount less than `minAmountLD` | Increase slippage tolerance or check token decimals |
| Compose message not received | Gas limit too low | Increase `composeGasLimit` in `extraOptions` |

---

### 3.5 Gas Fee Estimation Tool Missing (LOW ISSUE)

**Problem**: No easy way to estimate cross-chain gas fees before deployment.

#### Current workaround:

```typescript
// We had to call quoteSend() after deployment to estimate fees
const sendParam = { ... };
const [nativeFee, zroFee] = await zkk.quoteSend(sendParam, false);
console.log(`Estimated fee: ${ethers.formatEther(nativeFee)} ETH`);
```

**Problems:**
- Can only estimate fees AFTER deploying contracts
- Can't compare fees across different routes during planning
- No way to estimate fees in USD for budgeting

#### What would help:

✅ **Web-based fee calculator**: https://fees.layerzero.network/

**Features:**
- Input: source chain, destination chain, message size, compose message size
- Output: estimated native fee in USD and native token
- Historical fee data and trends

Example UI:

```
LayerZero Fee Estimator

From: [Ethereum Sepolia ▼]
To:   [Base Sepolia ▼]

Message size: [100] bytes
Compose message: [Yes ☑] [180] bytes

Estimated Fee: 0.0024 ETH ($4.32 USD)
  - Base fee: 0.0015 ETH
  - Compose gas: 0.0009 ETH

[Calculate] [Compare Routes]
```

✅ **Add fee estimation to LayerZero Scan** (before transaction)

✅ **SDK method for fee estimation**:

```typescript
import { estimateFee } from '@layerzerolabs/fee-estimator';

const feeEstimate = await estimateFee({
  srcEid: EndpointId.ETHEREUM_SEPOLIA,
  dstEid: EndpointId.BASE_SEPOLIA,
  messageSize: 100,
  composeMessageSize: 180,
  gasLimit: 300000
});

console.log(`Fee: ${feeEstimate.nativeFee} (${feeEstimate.usd})`);
```

---

## 4. Documentation Improvements Needed 📚

### High-Priority Additions:

#### 4.1 Compose Message Developer Guide ⚡ CRITICAL

**Why this is critical**: Compose messages are a powerful feature that differentiates LayerZero from other bridges, but they feel like a "hidden feature" due to lack of documentation.

**Suggested content:**

**Chapter 1: Introduction to Compose Messages**
- What are compose messages?
- When should you use them?
- Use cases and examples

**Chapter 2: Encoding Compose Messages**
```solidity
// Pattern 1: Manual encoding
bytes memory composeMsg = abi.encodePacked(
    txHash,        // bytes32
    timestamp,     // uint256
    amount,        // uint256
    recipient,     // address
    projectId,     // bytes32
    greedIndex     // uint256
);

// Pattern 2: ABI encoding (recommended for complex types)
bytes memory composeMsg = abi.encode(
    ComposeMsg({
        txHash: txHash,
        timestamp: timestamp,
        amount: amount,
        recipient: recipient,
        projectId: projectId,
        greedIndex: greedIndex
    })
);
```

**Chapter 3: Decoding Compose Messages**
```solidity
function lzCompose(..., bytes calldata _message, ...) external payable {
    // Pattern 1: Manual decoding
    bytes32 txHash = bytes32(_message[0:32]);
    uint256 timestamp = uint256(bytes32(_message[32:64]));

    // Pattern 2: ABI decoding
    ComposeMsg memory msg = abi.decode(_message, (ComposeMsg));
}
```

**Chapter 4: Gas Estimation**
- How to estimate gas for compose execution
- Common gas limits for different use cases
- How to set `composeGasLimit` in `extraOptions`

**Chapter 5: Testing Compose Messages**
- Unit testing encoding/decoding
- Integration testing with mock endpoints
- Debugging tips

**Chapter 6: Common Pitfalls**
- Message length validation
- Endianness issues
- Type conversion errors

---

#### 4.2 Testing Strategies Guide

**Content:**

**1. Mock Contracts for Local Testing**
```solidity
import {MockLayerZeroEndpoint} from "@layerzerolabs/test-helpers";

contract ZKKTest is Test {
    MockLayerZeroEndpoint lzEndpoint;

    function setUp() public {
        lzEndpoint = new MockLayerZeroEndpoint();
        // ... setup
    }
}
```

**2. Integration Test Patterns**
```javascript
// Hardhat test example
describe("Cross-chain transfer", () => {
  it("should send tokens from Sepolia to Base", async () => {
    // Setup
    const sendParam = { ... };

    // Execute
    await sepoliaZKK.send(sendParam, fee, refundAddress);

    // Verify (using LayerZero test helpers)
    await lz.deliverMessages(dstEid);
    expect(await baseZKK.balanceOf(recipient)).to.equal(amount);
  });
});
```

**3. Debugging Tips**
- Using LayerZero Scan for testnet debugging
- Reading compose message events
- Common error messages and solutions

---

#### 4.3 Migration Guide: V1 → V2

**Why this is needed**: Many blog posts and tutorials reference V1 APIs, causing confusion for new developers using V2.

**Content structure:**

| V1 API | V2 API | Notes |
|--------|--------|-------|
| `send()` with different params | `send(SendParam, MessagingFee, address)` | Simplified interface |
| `trustRemote()` | `setPeer(uint32, bytes32)` | New naming |
| Custom adapter config | `extraOptions` | Unified options |

**Code examples:**

```solidity
// V1 (OLD - Don't use)
function send(
    uint16 _dstChainId,
    bytes calldata _destination,
    bytes calldata _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
) external payable;

// V2 (NEW - Use this)
function send(
    SendParam calldata _sendParam,
    MessagingFee calldata _fee,
    address _refundAddress
) external payable returns (MessagingReceipt memory);
```

---

#### 4.4 Common Pitfalls & Solutions

**Content:**

**Pitfall 1: Address Encoding**

```solidity
// ❌ WRONG
await zkk.setPeer(dstEid, remoteAddress);

// ✅ CORRECT
await zkk.setPeer(dstEid, ethers.zeroPadValue(remoteAddress, 32));
```

**Why:** LayerZero uses `bytes32` for cross-chain addresses to support non-EVM chains.

---

**Pitfall 2: Peer Configuration Order**

```typescript
// ❌ WRONG - Only set peer on source chain
await sepoliaZKK.setPeer(baseEid, baseZKKAddress);

// ✅ CORRECT - Set peer on BOTH chains
await sepoliaZKK.setPeer(baseEid, baseZKKAddress);
await baseZKK.setPeer(sepoliaEid, sepoliaZKKAddress);
```

---

**Pitfall 3: Gas Estimation Errors**

```solidity
// ❌ WRONG - Insufficient gas for compose
const options = Options.newOptions().addExecutorLzReceiveOption(200000, 0);

// ✅ CORRECT - Sufficient gas for compose message processing
const options = Options.newOptions().addExecutorLzReceiveOption(300000, 0);
```

**Rule of thumb:**
- Simple OFT transfer: 200,000 gas
- OFT + simple compose: 300,000 gas
- OFT + complex compose (with storage writes): 500,000+ gas

---

### Medium-Priority:

#### 4.5 Advanced Patterns

**Topics:**

**1. Rate Limiting Cross-Chain Transfers**

```solidity
contract RateLimitedOFT is OFT {
    mapping(uint32 => uint256) public dailyLimit;
    mapping(uint32 => mapping(uint256 => uint256)) public dailySent;

    function send(...) external payable override {
        uint256 today = block.timestamp / 1 days;
        require(
            dailySent[_sendParam.dstEid][today] + _sendParam.amountLD <= dailyLimit[_sendParam.dstEid],
            "Daily limit exceeded"
        );

        dailySent[_sendParam.dstEid][today] += _sendParam.amountLD;
        super.send(...);
    }
}
```

**2. Batching Messages for Gas Optimization**

```solidity
// Batch multiple transfers in single cross-chain message
struct BatchTransfer {
    address[] recipients;
    uint256[] amounts;
}

function sendBatch(uint32 dstEid, BatchTransfer memory batch) external {
    bytes memory composeMsg = abi.encode(batch);
    // Send with compose message
}
```

**3. Combining OFT with Other Protocols**

Example: OFT + Uniswap v4 (like our ZakoKen project)

```solidity
contract ZKK is OFT {
    IUniswapV4Pool public uniswapPool;

    function lzCompose(...) external payable override {
        // Decode compose message
        // Auto-swap on destination chain
        uniswapPool.swap(...);
    }
}
```

---

#### 4.6 Security Best Practices

**Topics:**

**1. Access Control Patterns**

```solidity
// ❌ BAD: Anyone can mint
function mint(address to, uint256 amount) external {
    _mint(to, amount);
}

// ✅ GOOD: Only owner can mint
function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
}

// ✅ BETTER: Only LayerZero endpoint can trigger mints
function lzReceive(...) internal override {
    require(msg.sender == address(endpoint), "Only endpoint");
    _mint(recipient, amount);
}
```

**2. Reentrancy Considerations**

```solidity
// ✅ Safe pattern for compose messages
function lzCompose(...) external payable {
    // 1. Checks
    require(msg.sender == address(endpoint), "Only endpoint");

    // 2. Effects (state changes)
    balances[recipient] += amount;

    // 3. Interactions (external calls)
    IExternalContract(target).notify(recipient, amount);
}
```

**3. Message Replay Protection**

LayerZero provides built-in replay protection via message nonces, but you should also:

```solidity
mapping(bytes32 => bool) public processedMessages;

function lzCompose(..., bytes32 _guid, ...) external payable {
    require(!processedMessages[_guid], "Message already processed");
    processedMessages[_guid] = true;

    // Process message
}
```

---

## 5. Feature Requests 💡

### Would Significantly Improve Developer Experience:

#### 5.1 Hardhat Plugin: `@layerzerolabs/hardhat-layerzero`

**Why:** Simplify configuration and testing with a dedicated Hardhat plugin.

**Proposed API:**

```typescript
// hardhat.config.ts
import "@layerzerolabs/hardhat-layerzero";

export default {
  layerzero: {
    networks: {
      sepolia: {
        eid: 40161,
        endpoint: "0x6EDCE65403992e310A62460808c4b910D972f10f",
        rpcUrl: process.env.SEPOLIA_RPC_URL
      },
      baseSepolia: {
        eid: 40245,
        endpoint: "0x6EDCE65403992e310A62460808c4b910D972f10f",
        rpcUrl: process.env.BASE_SEPOLIA_RPC_URL
      }
    }
  }
};
```

**CLI Commands:**

```bash
# Auto-configure peers between deployed contracts
npx hardhat lz:configure --source sepolia --destination baseSepolia

# Send test message
npx hardhat lz:send --from sepolia --to baseSepolia --amount 100

# Check peer configuration
npx hardhat lz:peers --network sepolia
```

**Benefits:**
- Reduces boilerplate configuration code
- Standardizes deployment scripts
- Provides testing utilities out-of-the-box

---

#### 5.2 Compose Message Builder SDK

**Why:** Type-safe, intuitive API for building compose messages.

**Proposed API:**

```typescript
import { ComposeMessageBuilder } from '@layerzerolabs/oft-sdk';

// Fluent builder interface
const composeMsg = new ComposeMessageBuilder()
  .addBytes32('txHash', txHash)
  .addUint256('timestamp', Date.now())
  .addUint256('amount', parseEther("100"))
  .addAddress('recipient', recipientAddress)
  .addBytes32('projectId', projectId)
  .addUint256('greedIndex', 10000)
  .build();

// Type-safe encoding
const encoded = composeMsg.encode();

// Decoding
const decoded = ComposeMessageBuilder.decode(encodedMessage);
console.log(decoded.txHash, decoded.timestamp, decoded.amount);
```

**Benefits:**
- Eliminates manual byte manipulation
- Type safety prevents encoding errors
- Self-documenting code
- Easier to maintain and refactor

---

#### 5.3 Gas Estimation API

**Why:** Accurate gas estimation before deployment saves time and money.

**Proposed API:**

```typescript
import { estimateGas } from '@layerzerolabs/fee-estimator';

const gasEstimate = await estimateGas({
  srcEid: 40161, // Sepolia
  dstEid: 40245, // Base Sepolia
  message: messageBytes,
  composeMsg: composeMsgBytes,
  options: {
    lzReceiveGas: 200000,
    composeGas: 300000
  }
});

console.log(`
  Base Fee: ${gasEstimate.baseFee} ETH
  Execution Fee: ${gasEstimate.executionFee} ETH
  Compose Fee: ${gasEstimate.composeFee} ETH
  Total: ${gasEstimate.total} ETH (${gasEstimate.usd} USD)
`);
```

**Benefits:**
- Accurate cost planning for cross-chain operations
- Compare fees across different routes
- Budget estimation for production deployments

---

#### 5.4 LayerZero Scan API

**Why:** Programmatic access to transaction data for frontend integration and monitoring.

**Proposed API:**

```typescript
import { LayerZeroScan } from '@layerzerolabs/scan-api';

const scan = new LayerZeroScan({ network: 'testnet' });

// Get message status
const status = await scan.getMessageStatus(txHash);
console.log(status);
// {
//   status: 'DELIVERED',
//   srcChain: 'sepolia',
//   dstChain: 'base-sepolia',
//   srcTxHash: '0x...',
//   dstTxHash: '0x...',
//   composeStatus: 'SUCCESS',
//   timestamp: 1700000000
// }

// Track message in real-time
scan.watchMessage(txHash, (update) => {
  console.log(`Status: ${update.status}`);
  // SENT → INFLIGHT → DELIVERED → COMPOSED
});
```

**Use cases:**
- Frontend status displays
- Automated monitoring and alerting
- Analytics and reporting
- Integration testing

---

## 6. Specific Code That Frustrated Us 😤

### Example 1: Encoding Peer Address

**Current (confusing):**

```typescript
// contracts/scripts/configure-layerzero.ts:74
const peerAddress = ethers.zeroPadValue(baseSepoliaZKK, 32);
await sepoliaContract.setPeer(CHAIN_IDS.baseSepolia, peerAddress);
```

**Questions we had:**
- Why 32 bytes? Is this documented anywhere?
- What if I use 20 bytes (normal address size)?
- What happens on non-EVM chains?

**Wish we had:**

```typescript
import { encodePeerAddress } from '@layerzerolabs/devtools';

const encoded = encodePeerAddress(baseSepoliaZKK);
await sepoliaContract.setPeer(CHAIN_IDS.baseSepolia, encoded);

// With type safety:
// encodePeerAddress(address: string): `0x${string}` (32 bytes)
```

---

### Example 2: Building SendParam

**Current (error-prone):**

```typescript
const sendParam = {
  dstEid: 40245,
  to: ethers.zeroPadValue(recipient, 32),
  amountLD: amount,
  minAmountLD: amount,
  extraOptions: "0x",
  composeMsg: composeMessageBytes, // How to build this??? 🤷
  oftCmd: "0x"
};

// What is oftCmd? When should I use it?
// What format should extraOptions be?
// How do I set gas limits?
```

**Wish we had:**

```typescript
import { buildSendParam, Options, ComposeMessageBuilder } from '@layerzerolabs/oft-sdk';

const composeMsg = new ComposeMessageBuilder()
  .addBytes32('txHash', txHash)
  .addUint256('timestamp', Date.now())
  .build();

const options = Options.newOptions()
  .addExecutorLzReceiveOption(200000, 0)
  .addExecutorComposeOption(300000, 0);

const sendParam = buildSendParam({
  destinationEid: EndpointId.BASE_SEPOLIA,
  recipient: recipientAddress,
  amount: parseEther("100"),
  minAmount: parseEther("99"), // 1% slippage
  composeMsg: composeMsg,
  extraOptions: options
});

// Type-safe, self-documenting, hard to make mistakes
```

---

### Example 3: Testing Compose Messages

**Current (impossible locally):**

```typescript
// test/ZKK.test.ts
describe("Compose messages", () => {
  it("should process compose message", async () => {
    // ❌ Can't test this without deploying to testnet
    await zkk.send(...);

    // How do I trigger lzCompose locally?
    // No official mocks available
  });
});
```

**Wish we had:**

```typescript
import { MockLayerZeroEndpoint } from "@layerzerolabs/test-helpers";

describe("Compose messages", () => {
  let lzEndpoint: MockLayerZeroEndpoint;

  beforeEach(() => {
    lzEndpoint = new MockLayerZeroEndpoint();
    zkk = new ZKK("ZakoKen", "ZKK", lzEndpoint.address, owner, projectId);
  });

  it("should process compose message", async () => {
    const composeMsg = buildComposeMessage(...);

    // Mock endpoint auto-delivers compose message
    await zkk.send(sendParam, fee, refundAddress);

    // Compose message automatically processed
    expect(await zkk.processedMessages(guid)).to.be.true;
  });
});
```

---

## 7. Overall Developer Experience Rating

### Strengths: ⭐⭐⭐⭐⭐

**What LayerZero does exceptionally well:**

1. **Core Protocol Reliability**: Cross-chain messaging works flawlessly
2. **Testnet Infrastructure**: Stable, fast, and well-maintained
3. **LayerZero Scan**: Best-in-class block explorer for cross-chain transactions
4. **OFT Standard**: Clean, extensible contract architecture
5. **Multi-chain Support**: Wide network coverage

**These are genuine strengths that make LayerZero the best cross-chain messaging protocol.**

---

### Needs Improvement: ⭐⭐

**Where developer experience suffers:**

1. **Compose Message Documentation**: ⭐⭐ (MAJOR GAP)
   - Powerful feature, but feels hidden
   - Lack of examples wastes hours of developer time
   - No official encoding/decoding libraries

2. **TypeScript/SDK Ergonomics**: ⭐⭐⭐
   - Ethers v6 compatibility issues
   - Missing type definitions
   - Manual encoding required for common tasks

3. **Local Testing Tools**: ⭐⭐
   - No official mocks for LayerZero endpoints
   - Can't test cross-chain flows without testnet deployment
   - Slow iteration cycle during development

4. **Developer Tooling**: ⭐⭐⭐
   - No Hardhat/Foundry plugins
   - No CLI tools for common tasks
   - Manual configuration scripts required

---

### Overall: ⭐⭐⭐⭐ (4/5)

**Summary:**
- LayerZero's **core technology is excellent** (5/5)
- LayerZero's **developer experience is good** (4/5)
- With **better documentation and tooling**, this would easily be **5/5**

**The gap:** LayerZero is powerful, but **compose messages feel like a hidden feature** rather than a well-documented capability.

---

## 8. What Success Looks Like 🎯

**If you implement our feedback, future developers should:**

1. ✅ **Find a complete compose message example in docs within 5 minutes**
   - Current: 4+ hours of reverse engineering
   - Target: Clear example on first page of compose message guide

2. ✅ **Test cross-chain OFT with compose messages locally without deploying**
   - Current: Must deploy to testnet for every test
   - Target: Full test suite runs locally in <1 minute

3. ✅ **Get clear error messages when configuration is wrong**
   - Current: "OApp: invalid endpoint caller" (cryptic)
   - Target: "OApp: peer not set for source chain 40161" (actionable)

4. ✅ **Estimate gas fees accurately before deployment**
   - Current: Can only estimate after deployment
   - Target: Web calculator + SDK method for fee estimation

5. ✅ **Have type-safe TypeScript support for all LayerZero operations**
   - Current: Manual type casting, loss of type safety
   - Target: Full TypeScript support with auto-generated types

6. ✅ **Deploy and configure cross-chain contracts with CLI commands**
   - Current: Custom scripts for each project
   - Target: `npx hardhat lz:configure --source sepolia --destination base`

---

## 9. Impact on Our Project

**Time Spent on LayerZero Integration:**
- Total development time: ~20 hours
- Time debugging compose messages: ~6 hours (30%)
- Time writing custom tooling: ~3 hours (15%)
- Time on testnet deployments: ~2 hours (10%)

**What we achieved:**
- ✅ Working cross-chain OFT token (ZKK)
- ✅ Custom compose message implementation for transaction metadata
- ✅ Deployment on Sepolia ↔ Base Sepolia
- ✅ Successfully demonstrated for ETHGlobal hackathon

**What would have been faster with better docs/tools:**
- Compose messages: 6 hours → 1 hour (5 hours saved)
- Testing: 3 hours → 0.5 hours (2.5 hours saved)
- Configuration: 2 hours → 0.5 hours (1.5 hours saved)

**Total potential time savings: 9 hours (45% reduction)**

---

## 10. Contact & Collaboration 🤝

We're happy to:

✅ **Provide our mock contracts** to help build official testing tools

✅ **Review any documentation improvements** (we know the pain points!)

✅ **Test beta versions** of new SDK features

✅ **Contribute code examples** to official docs

✅ **Participate in developer feedback sessions**

**Contact:**
- **GitHub**: https://github.com/ZakoDAO/ZakoKen
- **Project**: ZakoKen - Dynamic Fundraising Stablecoin Protocol
- **Event**: ETHGlobal Buenos Aires 2025

**Related Issues We Could Create:**
- [ ] Feature Request: Official Mock Contracts for Testing
- [ ] Documentation: Compose Message Developer Guide
- [ ] Feature Request: Hardhat Plugin for LayerZero
- [ ] Bug Report: TypeScript Types Missing for OFT Methods

---

## 11. One Thing We Really Want 🙏

**If LayerZero could only improve ONE thing based on our feedback:**

### → Comprehensive Compose Message Documentation with Examples

**Why this matters most:**

1. **Time saved**: Would save every new developer 4-6 hours of frustration
2. **Feature adoption**: Compose messages are powerful, but underutilized due to lack of docs
3. **Ecosystem growth**: Better docs = more innovative projects using LayerZero
4. **Developer satisfaction**: Documentation quality directly impacts developer experience

**What this documentation should include:**

- ✅ Full end-to-end example (Solidity + TypeScript)
- ✅ Encoding/decoding patterns with code examples
- ✅ Gas estimation guidelines
- ✅ Testing strategies
- ✅ Common pitfalls and solutions
- ✅ Real-world use cases

**Impact:** This single improvement would elevate LayerZero from "great protocol" to "great developer experience."

---

## 12. Appendix: Code Samples from Our Project

### A. Our Compose Message Implementation

```solidity
// contracts/src/ZKK.sol (simplified)

/**
 * @notice Handle composed messages from LayerZero
 * @dev Only callable by LayerZero endpoint
 */
function lzCompose(
    address _from,
    bytes32 _guid,
    bytes calldata _message,
    address, // _executor
    bytes calldata // _extraData
) external payable {
    // Validation
    require(msg.sender == address(endpoint), "OFT: only endpoint can call");
    require(_message.length >= 180, "Invalid message length");

    // Manual byte slicing (we wish we had a better way!)
    bytes32 txHash = bytes32(_message[0:32]);
    uint256 timestamp = uint256(bytes32(_message[32:64]));
    uint256 amount = uint256(bytes32(_message[64:96]));
    address recipient = address(bytes20(_message[96:116]));
    bytes32 msgProjectId = bytes32(_message[116:148]);
    uint256 greedIndex = uint256(bytes32(_message[148:180]));

    // Emit event for transparency
    emit ComposeMessageReceived(_guid, _from, _message);
    emit TokensMinted(recipient, amount, txHash, msgProjectId, greedIndex, timestamp);
}
```

### B. Our Deployment Script

```typescript
// contracts/scripts/deploy-zkk.ts (simplified)

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();

  // Get LayerZero endpoint
  const lzEndpoint = LZ_ENDPOINTS[networkName];

  // Deploy ZKK
  const ZKK = await ethers.getContractFactory("ZKK");
  const zkk = await ZKK.deploy(
    "ZakoKen",
    "ZKK",
    lzEndpoint,
    deployer.address,
    DEFAULT_PROJECT_ID
  );
  await zkk.waitForDeployment();

  console.log("✅ ZKK deployed to:", await zkk.getAddress());
}
```

### C. Our Cross-Chain Configuration Script

```typescript
// contracts/scripts/configure-layerzero.ts (simplified)

async function configurePeers() {
  // Load deployment addresses
  const sepoliaZKK = deployments.sepolia.ZKK;
  const baseSepoliaZKK = deployments.baseSepolia.ZKK;

  // Configure Sepolia → Base Sepolia
  const sepoliaContract = await ethers.getContractAt("ZKK", sepoliaZKK);
  const peerAddress = ethers.zeroPadValue(baseSepoliaZKK, 32);

  await sepoliaContract.setPeer(CHAIN_IDS.baseSepolia, peerAddress);
  console.log("✅ Peer set on Sepolia");

  // Configure Base Sepolia → Sepolia
  const baseSepoliaContract = await ethers.getContractAt("ZKK", baseSepoliaZKK);
  const sepoliaPeerAddress = ethers.zeroPadValue(sepoliaZKK, 32);

  await baseSepoliaContract.setPeer(CHAIN_IDS.sepolia, sepoliaPeerAddress);
  console.log("✅ Peer set on Base Sepolia");
}
```

---

## 13. Final Thoughts

**What we love about LayerZero:**
- Best-in-class cross-chain messaging protocol
- Reliable, fast, and well-designed
- Strong technical foundation
- Active community and support

**What would make us love it even more:**
- Better documentation for advanced features (compose messages!)
- Modern TypeScript/SDK support
- Official testing tools
- Developer-friendly tooling (CLI, plugins)

**Bottom line:** LayerZero has the best technology in the cross-chain space. With improved developer experience, it would be unbeatable.

Thank you for building LayerZero and for listening to developer feedback! 🙏

---

**Submitted by:** ZakoKen Team
**Date:** November 23, 2025
**Event:** ETHGlobal Buenos Aires 2025
**Prize Category:** Best Developer Feedback ($750)
