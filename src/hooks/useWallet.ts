import { useAppKitAccount, useAppKit, useAppKitState } from "@reown/appkit/react";

export function useWallet() {
  const { address, isConnected, caipAddress } = useAppKitAccount();
  const { open } = useAppKit();
  const { selectedNetworkId } = useAppKitState();

  const shortAddress = address
    ? `${address.slice(0, 6)}...${address.slice(-4)}`
    : null;

  const isHederaTestnet = selectedNetworkId === "eip155:296";

  return {
    address: address ?? null,
    shortAddress,
    isConnected,
    caipAddress,
    isHederaTestnet,
    openModal: () => open(),
    openNetworkModal: () => open({ view: "Networks" }),
  };
}
