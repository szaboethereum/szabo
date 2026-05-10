"use client";

import "@rainbow-me/rainbowkit/styles.css";
import {
  getDefaultConfig,
  RainbowKitProvider,
  darkTheme,
} from "@rainbow-me/rainbowkit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider, http } from "wagmi";
import { mainnet } from "wagmi/chains";
import { type ReactNode, useState } from "react";

const config = getDefaultConfig({
  appName: "SZABO",
  projectId: "f179ef6f3b3cf054e5c286fa26a31630",
  chains: [mainnet],
  transports: {
    [mainnet.id]: http("https://ethereum-rpc.publicnode.com"),
  },
});

export function Providers({ children }: { children: ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          theme={darkTheme({
            accentColor: "#33ff33",
            accentColorForeground: "#0a0a0a",
            borderRadius: "none",
            fontStack: "system",
          })}
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
