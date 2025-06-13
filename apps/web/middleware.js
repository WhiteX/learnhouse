import { NextResponse } from 'next/server';

// This middleware runs on every request
export function middleware(request) {
  // Get the current hostname from the request headers
  const currentHostname = request.headers.get('host');
  
  // Always inspect for cross-domain requests regardless of referrer
  const url = request.nextUrl.clone();
  const path = url.pathname;
  
  // Check for common patterns that might indicate cross-domain content
  // 1. Handle image files that might be requested from the wrong domain
  if (path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg') || 
      path.endsWith('.gif') || path.endsWith('.webp') || path.endsWith('.svg')) {
    // Ensure image path is properly routed to current domain
    if (path.includes('empty_avatar.png')) {
      console.log(`Intercepting image request: ${path}`);
      // Rewrite all empty_avatar.png requests to use the local domain
      return NextResponse.rewrite(new URL(`/images/empty_avatar.png`, request.url));
    }
  }
  
  // 2. Check if request is going to the wrong domain through API path
  if (path.includes('/api/') && request.headers.has('referer')) {
    const refererUrl = new URL(request.headers.get('referer'));
    // If referer domain doesn't match the requested API domain, redirect
    if (refererUrl.hostname !== currentHostname) {
      console.log(`Redirecting cross-domain API request: ${path}`);
      const newUrl = new URL(path, `https://${currentHostname}`);
      return NextResponse.redirect(newUrl);
    }
  }

  // Get the referrer URL if it exists
  const referer = request.headers.get('referer');

  // If there is a referrer, check if it's from a different domain
  if (referer) {
    try {
      const refererUrl = new URL(referer);
      const refererHostname = refererUrl.hostname;

      // If the referrer hostname doesn't match the current hostname
      if (refererHostname !== currentHostname) {
        console.log(`Cross-domain request detected: ${refererHostname} -> ${currentHostname}`);
        
        // For path segments that might include another domain
        if (path.includes('/next/static/') || path.includes('/api/')) {
          // Ensure all paths use the current hostname
          // This prevents asset URL problems when different hostnames appear in the path
          const localPath = path.replace(/https?:\/\/[^\/]+/, '');
          url.pathname = localPath;
          return NextResponse.rewrite(url);
        }
      }
    } catch (e) {
      console.error('Error processing referer in middleware:', e);
    }
  }

  // Continue with the request as normal
  return NextResponse.next();
}

// Configure which paths this middleware will run on
export const config = {
  matcher: [
    // Apply to all paths
    '/:path*',
  ],
};