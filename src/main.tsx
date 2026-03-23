import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";
// Init Reown AppKit (wallet connect) before render
import "./lib/wallet";

createRoot(document.getElementById("root")!).render(<App />);
