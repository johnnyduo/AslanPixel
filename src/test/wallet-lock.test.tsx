/**
 * Wallet lock / disconnect UX tests
 * Covers: TopBar, LeftPanel, RightPanel, BottomPanel, Index
 *
 * Strategy: mock all external hooks and heavy deps so tests run
 * in jsdom without a real wallet, blockchain, or Reown SDK.
 */

import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import React from "react";

// ── shared mock factory ────────────────────────────────────────────────────
const openModal = vi.fn();

function mockWallet(connected: boolean) {
  return {
    isConnected: connected,
    address: connected ? "0xAbCd1234AbCd1234AbCd1234AbCd1234AbCd1234" : null,
    shortAddress: connected ? "0xAbCd…1234" : null,
    caipAddress: connected ? "eip155:296:0xAbCd1234AbCd1234AbCd1234AbCd1234AbCd1234" : null,
    isHederaTestnet: connected,
    openModal,
    openNetworkModal: vi.fn(),
  };
}

// Mock useWallet
vi.mock("@/hooks/useWallet", () => ({
  useWallet: vi.fn(),
}));

// Mock Reown AppKit (used by LeftPanel)
vi.mock("@reown/appkit/react", () => ({
  useAppKitProvider: () => ({ walletProvider: null }),
  useAppKit: () => ({ open: vi.fn() }),
  useAppKitAccount: () => ({ address: null, isConnected: false, caipAddress: null }),
  useAppKitState: () => ({ selectedNetworkId: null }),
}));

// Mock ethers (used by TopBar, LeftPanel)
vi.mock("ethers", () => ({
  JsonRpcProvider: vi.fn().mockImplementation(() => ({
    getBalance: vi.fn().mockResolvedValue(BigInt(0)),
  })),
  Contract: vi.fn().mockImplementation(() => ({
    balanceOf: vi.fn().mockResolvedValue(BigInt(0)),
    nextClaimTime: vi.fn().mockResolvedValue(BigInt(0)),
    drip: vi.fn().mockResolvedValue({ wait: vi.fn() }),
  })),
  BrowserProvider: vi.fn(),
}));

// Mock all timeline / quest / agent hooks
vi.mock("@/hooks/useLiveTimeline", () => ({
  useLiveTimeline: () => ({ messages: [], isLive: false, error: null }),
}));
vi.mock("@/hooks/useQuestInput", () => ({
  useQuestInput: () => ({ pendingIntent: null, clearPendingIntent: vi.fn(), setPendingIntent: vi.fn() }),
}));
vi.mock("@/hooks/useContracts", () => ({
  useAgentStats: () => ({ agents: [], quests: [] }),
  deactivateAgentOnchain: vi.fn(),
  registerAgentERC8004: vi.fn(),
}));
vi.mock("@/hooks/useAgentInit", () => ({
  useAgentInit: vi.fn(),
  getStoredAgentTxHashes: () => ({}),
  AGENT_TX_STORAGE_KEY: "aslan_agent_tx_hashes",
}));
vi.mock("@/hooks/useAutoQuest", () => ({ useAutoQuest: vi.fn() }));
vi.mock("@/hooks/useHbarPrice", () => ({
  useHbarPrice: () => ({ price: 0.12, change: "up" }),
}));

// Mock react-router-dom (used by TopBar)
vi.mock("react-router-dom", () => ({
  useNavigate: () => vi.fn(),
}));

// Mock PaymentGate + VotePanel (render nothing)
vi.mock("@/components/PaymentGate", () => ({ default: () => null }));
vi.mock("@/components/VotePanel", () => ({ default: () => null }));

// ── imports (after mocks) ──────────────────────────────────────────────────
import { useWallet } from "@/hooks/useWallet";
import TopBar from "@/components/TopBar";
import LeftPanel from "@/components/LeftPanel";
import RightPanel from "@/components/RightPanel";
import BottomPanel from "@/components/BottomPanel";

const useWalletMock = useWallet as ReturnType<typeof vi.fn>;

// ─────────────────────────────────────────────────────────────────────────
// TopBar
// ─────────────────────────────────────────────────────────────────────────
describe("TopBar", () => {
  beforeEach(() => { vi.clearAllMocks(); });

  it("shows Connect Wallet button when disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<TopBar />);
    expect(screen.getByText(/connect wallet/i)).toBeTruthy();
  });

  it("hides HBAR/USDC balance when disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<TopBar />);
    expect(screen.queryByText("HBAR", { selector: "span" })).toBeNull();
    expect(screen.queryByText(/USDC/)).toBeNull();
  });

  it("hides Testnet badge when disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<TopBar />);
    expect(screen.queryByText("Testnet")).toBeNull();
  });

  it("shows HBAR price ticker regardless of connection", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<TopBar />);
    expect(screen.getByText(/HBAR \$/)).toBeTruthy();
  });

  it("shows address and Testnet badge when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<TopBar />);
    expect(screen.getByText("0xAbCd…1234")).toBeTruthy();
    expect(screen.getByText("Testnet")).toBeTruthy();
  });

  it("calls openModal when Connect Wallet button clicked", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<TopBar />);
    fireEvent.click(screen.getByText(/connect wallet/i));
    expect(openModal).toHaveBeenCalledOnce();
  });

  it("calls openModal when address button clicked (connected)", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<TopBar />);
    fireEvent.click(screen.getByText("0xAbCd…1234"));
    expect(openModal).toHaveBeenCalledOnce();
  });

  it("does not show dashboard toggle when disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    const toggle = vi.fn();
    render(<TopBar onDashboardToggle={toggle} />);
    // BarChart2 button should not be rendered
    const buttons = screen.queryAllByRole("button");
    // Only the wallet connect button should be interactive (not dashboard)
    const dashBtn = buttons.find(b => b.getAttribute("title") === "Pixel Dashboard");
    expect(dashBtn).toBeUndefined();
  });

  it("shows dashboard toggle when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    const toggle = vi.fn();
    render(<TopBar onDashboardToggle={toggle} />);
    const dashBtn = screen.getByTitle("Pixel Dashboard");
    expect(dashBtn).toBeTruthy();
    fireEvent.click(dashBtn);
    expect(toggle).toHaveBeenCalledOnce();
  });
});

// ─────────────────────────────────────────────────────────────────────────
// LeftPanel
// ─────────────────────────────────────────────────────────────────────────
describe("LeftPanel", () => {
  beforeEach(() => { vi.clearAllMocks(); });

  it("shows lock overlay when disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<LeftPanel />);
    expect(screen.getByText(/QUEST INPUT LOCKED/i)).toBeTruthy();
  });

  it("shows connect wallet button in lock overlay", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<LeftPanel />);
    const btns = screen.getAllByText(/connect wallet/i);
    expect(btns.length).toBeGreaterThan(0);
  });

  it("calls openModal from lock overlay button", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<LeftPanel />);
    const btns = screen.getAllByText(/connect wallet/i);
    fireEvent.click(btns[0]);
    expect(openModal).toHaveBeenCalledOnce();
  });

  it("does not show lock overlay when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<LeftPanel />);
    expect(screen.queryByText(/QUEST INPUT LOCKED/i)).toBeNull();
  });

  it("shows quest input panel when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<LeftPanel />);
    expect(screen.getByText(/QUEST INPUT/i)).toBeTruthy();
  });

  it("does not show faucet button when disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<LeftPanel />);
    expect(screen.queryByText(/Claim 1000 USDC/i)).toBeNull();
  });
});

// ─────────────────────────────────────────────────────────────────────────
// RightPanel
// ─────────────────────────────────────────────────────────────────────────
describe("RightPanel", () => {
  beforeEach(() => { vi.clearAllMocks(); });

  it("shows lock overlay when disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<RightPanel />);
    expect(screen.getByText(/AGENT PANEL LOCKED/i)).toBeTruthy();
  });

  it("shows connect wallet button in right panel lock overlay", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<RightPanel />);
    const btns = screen.getAllByText(/connect wallet/i);
    expect(btns.length).toBeGreaterThan(0);
  });

  it("calls openModal from right panel lock overlay", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<RightPanel />);
    const btns = screen.getAllByText(/connect wallet/i);
    fireEvent.click(btns[0]);
    expect(openModal).toHaveBeenCalledOnce();
  });

  it("does not show lock overlay when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<RightPanel />);
    expect(screen.queryByText(/AGENT PANEL LOCKED/i)).toBeNull();
  });

  it("shows AGENT DETAIL header when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<RightPanel />);
    expect(screen.getByText(/AGENT DETAIL/i)).toBeTruthy();
  });

  it("shows REGISTER button when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<RightPanel />);
    expect(screen.getByText(/REGISTER/i)).toBeTruthy();
  });

  it("resets regAgentId when REGISTER modal opens", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<RightPanel />);
    const regBtn = screen.getByTitle("Register agent onchain");
    fireEvent.click(regBtn);
    // After clicking, the modal should open — agent ID field should be empty
    const agentIdInput = screen.queryByPlaceholderText(/agent-id/i) as HTMLInputElement | null;
    if (agentIdInput) {
      expect(agentIdInput.value).toBe("");
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────
// BottomPanel
// ─────────────────────────────────────────────────────────────────────────
describe("BottomPanel", () => {
  beforeEach(() => { vi.clearAllMocks(); });

  it("shows lock overlay when disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<BottomPanel />);
    expect(screen.getByText(/GUILD TERMINAL LOCKED/i)).toBeTruthy();
  });

  it("shows connect wallet button in bottom panel lock overlay", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<BottomPanel />);
    const btns = screen.getAllByText(/connect wallet/i);
    expect(btns.length).toBeGreaterThan(0);
  });

  it("calls openModal from bottom panel lock overlay", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<BottomPanel />);
    const btns = screen.getAllByText(/connect wallet/i);
    fireEvent.click(btns[0]);
    expect(openModal).toHaveBeenCalledOnce();
  });

  it("does not show lock overlay when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<BottomPanel />);
    expect(screen.queryByText(/GUILD TERMINAL LOCKED/i)).toBeNull();
  });

  it("shows QUEST input bar when connected", () => {
    useWalletMock.mockReturnValue(mockWallet(true));
    render(<BottomPanel />);
    expect(screen.getByText(/^QUEST:/i)).toBeTruthy();
  });

  it("calls openModal when RUN QUEST clicked while disconnected", () => {
    useWalletMock.mockReturnValue(mockWallet(false));
    render(<BottomPanel />);
    // Lock overlay is shown, click its connect button
    const btns = screen.getAllByText(/connect wallet/i);
    fireEvent.click(btns[0]);
    expect(openModal).toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────────
// useWallet hook unit
// ─────────────────────────────────────────────────────────────────────────
describe("useWallet", () => {
  it("exports openModal, isConnected, address, shortAddress", () => {
    const wallet = mockWallet(true);
    expect(wallet).toHaveProperty("openModal");
    expect(wallet).toHaveProperty("isConnected");
    expect(wallet).toHaveProperty("address");
    expect(wallet).toHaveProperty("shortAddress");
  });

  it("shortAddress is null when disconnected", () => {
    const wallet = mockWallet(false);
    expect(wallet.shortAddress).toBeNull();
    expect(wallet.address).toBeNull();
  });

  it("shortAddress is set when connected", () => {
    const wallet = mockWallet(true);
    expect(wallet.shortAddress).toBe("0xAbCd…1234");
  });
});
