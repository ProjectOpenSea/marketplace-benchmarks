pragma solidity >=0.8.7;

import "../MarketConfig.sol";
import "./lib/ConsiderationStructs.sol";
import "./lib/ConsiderationTypeHashes.sol";

contract OpenSeaConfig is MarketConfig, ConsiderationTypeHashes {
    address internal constant marketplace = address(0x00000000006CEE72100D161c57ADA5Bb2be1CA79);

    address internal constant approvalTarget = address(0x00000000006CEE72100D161c57ADA5Bb2be1CA79);

    function getOrder(CFG_OrderDetails memory orderDetails) internal view returns (OrderParameters memory components) {
      components.offerer = orderDetails.offerer;
      components.offer = new OfferItem[](orderDetails.offeredAssets.length);
      components.consideration = new ConsiderationItem[](
        orderDetails.fulfilledAssets.length +
        orderDetails.fees.length
      );
      components.startTime = 0;
      components.endTime = block.timestamp + 1;
    }

    function getOrderSignatureDigest(CFG_OrderDetails memory orderDetails) external view virtual override returns (bytes32 digest, bool) {
      digest = _deriveOrderHash(getOrder(orderDetails), 0);
    }

    function getSwapCalls(CFG_OrderDetails memory orderDetails, bytes memory signature)
        external
        view
        virtual
        override
        returns (CFG_Call[] memory swapCalls)
    {
      OrderParameters memory params = getOrder(orderDetails);
      OfferItem [] memory offer = params.offer;
      ConsiderationItem [] memory consideration = params.consideration;
      if (offer.length == 1) {
        uint256 considerationLength = consideration.length;
        bool canBeBasicOrder = params.consideration[1].recipient == params.offerer;
        uint256 numErc721OrErc1155;
        for (uint256 i; i < considerationLength; ++i) {
          // if (consideration)
        }
        
        if (!canBeBasicOrder) {
          ItemType secondItemType = consideration[1].itemType;
          bool allSameItemType = true;
          for (uint256 i = 2; i < considerationLength; ++i) {
            if (consideration[i].itemType != secondItemType) {
              allSameItemType = false;
            }
          }
          if (allSameItemType) {
            canBeBasicOrder = true;
          }
        }
      }
    }
}

contract SeaportConfig {
    address public constant marketplace = address(0x00000000006CEE72100D161c57ADA5Bb2be1CA79);

    address public constant approvalTarget = address(0x00000000006CEE72100D161c57ADA5Bb2be1CA79);

    /// Get whatever needs to be signed for the given test.
    function simpleSwapDigest() external view returns (bytes32 digest, bool use2098) {
        bytes32 orderHash = bytes32(0); // TODO

        bytes32 domainSeparator = bytes32(0x0a8f10d275e6dd59030d0b1d6aa63bf27c249f4e420c727533c0f7f0f2e75261);

        digest = keccak256(abi.encodePacked(bytes2(0x1901), domainSeparator, orderHash));

        use2098 = true;
    }

    /// Supply signature and translate into the call to make for the test.
    function simpleSwapPayload(bytes memory signature) external view returns (uint256 value, bytes memory callData) {
        // Derive and return the value and calldata required for the test.
        value = 0;

        // TODO
        bytes4 functionSelector = bytes4(0x12345678);
        uint256 arg1 = 69420;

        callData = abi.encodeWithSelector(functionSelector, arg1, signature);
    }
}
