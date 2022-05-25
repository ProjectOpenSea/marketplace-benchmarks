enum CFG_ItemType {
  ETH,
  ERC20,
  ERC721,
  ERC1155
}

struct CFG_Item {
  CFG_ItemType itemType;
  address recipient;
  address token;
  uint256 amount;
  uint256 identifier;
}

enum CFG_CallType {
  UserSetup, // one time user setup for market - count towards user setup cost but not swap cost
  OrderSetup, // per-order setup call - count towards setup call
  Swap // transaction to execute a swap
}

enum CFG_ListingType {
  SignedOrder,
  OnChainListedOrder
}

struct CFG_Call {
  CFG_CallType callType;
  address sender;
  address target;
  uint256 value;
  bytes data;
}

struct CFG_OrderDetails {
  CFG_ListingType listingType;
  address offerer;
  address fulfiller;
  CFG_Item[] offeredAssets;
  CFG_Item[] fulfilledAssets;
  CFG_Item[] fees;
}

abstract contract MarketConfig {
  function getOrderSignatureDigest(
    CFG_OrderDetails memory orderDetails
  ) external view virtual returns (bytes32 digest, bool use2098);

  function getUserSetupCalls(CFG_OrderDetails memory orderDetails) external view virtual returns (CFG_Call[] memory calls) {}

  function getSwapCalls(
    CFG_OrderDetails memory orderDetails,
    bytes calldata signature
  ) external view virtual returns (CFG_Call[] memory swapCalls);
}