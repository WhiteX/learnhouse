(function() {
  // Get the current domain
  const currentDomain = window.location.hostname;
  console.log("[Domain Isolation] Current domain:", currentDomain);
  
  // Check if RUNTIME_CONFIG is available
  if (!window.RUNTIME_CONFIG) {
    console.warn("[Domain Isolation] Runtime config not found, creating empty one.");
    window.RUNTIME_CONFIG = {};
  }
  
  // Store the domain info globally
  window.LEARNHOUSE_DOMAIN = currentDomain;
  
  // 1. Intercept fetch API
  const originalFetch = window.fetch;
  window.fetch = function(url, options) {
    if (typeof url === "string") {
      try {
        // Handle both absolute and relative URLs
        const urlObj = new URL(url, window.location.origin);
        const targetDomain = urlObj.hostname;
        
        // If URL has a different domain than current domain, rewrite it
        if (targetDomain !== currentDomain) {
          // Allow external APIs like umami
          if (targetDomain.includes('api-gateway.umami.dev')) {
            return originalFetch(url, options);
          }
          
          console.warn("[Domain Isolation] Redirecting request to current domain:", url);
          const newUrl = url.replace(/https?:\/\/[^\/]+/, window.location.origin);
          console.log("[Domain Isolation] New URL:", newUrl);
          return originalFetch(newUrl, options);
        }
      } catch (e) {
        console.error("[Domain Isolation] Error processing URL:", e);
      }
    }
    return originalFetch(url, options);
  };
  
  // 2. Intercept XMLHttpRequest
  const originalXHROpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url, ...rest) {
    if (typeof url === "string") {
      try {
        const urlObj = new URL(url, window.location.origin);
        const targetDomain = urlObj.hostname;
        
        if (targetDomain !== currentDomain) {
          // Allow external APIs
          if (targetDomain.includes('api-gateway.umami.dev')) {
            return originalXHROpen.call(this, method, url, ...rest);
          }
          
          console.warn("[Domain Isolation] Redirecting XHR to current domain:", url);
          const newUrl = url.replace(/https?:\/\/[^\/]+/, window.location.origin);
          console.log("[Domain Isolation] New XHR URL:", newUrl);
          return originalXHROpen.call(this, method, newUrl, ...rest);
        }
      } catch (e) {
        console.error("[Domain Isolation] Error processing XHR URL:", e);
      }
    }
    return originalXHROpen.call(this, method, url, ...rest);
  };
  
  // 3. Fix Next.js chunk loading issues
  const originalReactDOMCreateScriptHook = Object.getOwnPropertyDescriptor(HTMLScriptElement.prototype, 'src');
  if (originalReactDOMCreateScriptHook) {
    Object.defineProperty(HTMLScriptElement.prototype, 'src', {
      get: originalReactDOMCreateScriptHook.get,
      set: function(url) {
        if (typeof url === 'string') {
          try {
            const urlObj = new URL(url, window.location.origin);
            const targetDomain = urlObj.hostname;
            
            if (targetDomain !== currentDomain && url.includes('/next/static/chunks/')) {
              const newUrl = url.replace(/https?:\/\/[^\/]+/, window.location.origin);
              console.warn("[Domain Isolation] Redirecting script src to current domain:", url);
              console.log("[Domain Isolation] New script src:", newUrl);
              return originalReactDOMCreateScriptHook.set.call(this, newUrl);
            }
          } catch (e) {
            console.error("[Domain Isolation] Error processing script URL:", e);
          }
        }
        return originalReactDOMCreateScriptHook.set.call(this, url);
      },
      configurable: true
    });
  }
  
  console.log("[Domain Isolation] Complete domain isolation system installed");
})();