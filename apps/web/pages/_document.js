import { Html, Head, Main, NextScript } from 'next/document';

export default function Document() {
  return (
    <Html lang="en">
      <Head>
        {/* Load domain isolation loader first - immediate protection */}
        <script src="/domain-isolation-loader.js" strategy="beforeInteractive" />
        {/* Load runtime configuration */}
        <script src="/runtime-config.js" strategy="beforeInteractive" />
        {/* Load comprehensive API interceptor */}
        <script src="/api-interceptor.js" strategy="beforeInteractive" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}