import { useState } from "react";

import logo from "./assets/logo.svg";

export default function App() {
  const [count, setCount] = useState(0);
  const [health, setHealth] = useState("not checked");

  async function checkApi() {
    try {
      const response = await fetch("/api/v1/health");
      setHealth((await response.json()).status);
    } catch {
      setHealth("backend not reachable");
    }
  }

  return (
    <main className="page">
      <img src={logo} className="logo" alt="logo" />
      <h1>Vite + React template</h1>
      <p>Edit src/App.jsx and save to see hot reload.</p>
      <button onClick={() => setCount((c) => c + 1)}>count is {count}</button>
      <button onClick={checkApi}>API health: {health}</button>
    </main>
  );
}
