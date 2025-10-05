"use client";

import { useEffect, useRef } from 'react';

export default function GamePage() {
  const iframeRef = useRef<HTMLIFrameElement>(null);

  return (
    <div style={{ width: '100vw', height: '100vh', background: 'black' }}>
      <iframe
        ref={iframeRef}
        src="/game/CoinThing.html"
        style={{
          width: '100%',
          height: '100%',
          border: 'none',
        }}
        title="Coin Blaster"
      ></iframe>
    </div>
  );
}
