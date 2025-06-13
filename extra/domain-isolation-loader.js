// Domain Isolation Loader
// This script loads before any other scripts to ensure all requests stay within the current domain

(function() {
  console.log('[Domain Isolation] Initializing early domain isolation...');
  
  // Override createElement to patch script elements before they load
  const originalCreateElement = document.createElement.bind(document);
  document.createElement = function(tagName) {
    const element = originalCreateElement(tagName);
    
    if (tagName.toLowerCase() === 'script') {
      const originalSetAttribute = element.setAttribute.bind(element);
      element.setAttribute = function(name, value) {
        if (name === 'src' && typeof value === 'string') {
          try {
            const currentDomain = window.location.hostname;
            const urlObj = new URL(value, window.location.origin);
            const targetDomain = urlObj.hostname;
            
            if (targetDomain !== currentDomain) {
              console.warn('[Domain Isolation] Pre-load intercepted cross-domain script:', value);
              value = value.replace(/https?:\/\/[^\/]+/, window.location.origin);
              console.log('[Domain Isolation] Changed to:', value);
            }
          } catch (e) {
            console.error('[Domain Isolation] Error processing script URL:', e);
          }
        }
        return originalSetAttribute(name, value);
      };
    }
    
    return element;
  };
  
  // Store original URL manipulation methods
  window.__domainIsolationOriginals = {
    fetch: window.fetch,
    open: XMLHttpRequest.prototype.open
  };
  
  // Simple early fetch override
  window.fetch = function(url, options) {
    if (typeof url === 'string') {
      try {
        const currentDomain = window.location.hostname;
        const urlObj = new URL(url, window.location.origin);
        const targetDomain = urlObj.hostname;
        
        if (targetDomain !== currentDomain) {
          console.warn('[Domain Isolation] Early loader redirecting fetch:', url);
          url = url.replace(/https?:\/\/[^\/]+/, window.location.origin);
        }
      } catch (e) {
        console.error('[Domain Isolation] Early loader error:', e);
      }
    }
    return window.__domainIsolationOriginals.fetch.apply(this, arguments);
  };
  
  // Simple early XHR override
  XMLHttpRequest.prototype.open = function(method, url, ...args) {
    if (typeof url === 'string') {
      try {
        const currentDomain = window.location.hostname;
        const urlObj = new URL(url, window.location.origin);
        const targetDomain = urlObj.hostname;
        
        if (targetDomain !== currentDomain) {
          console.warn('[Domain Isolation] Early loader redirecting XHR:', url);
          url = url.replace(/https?:\/\/[^\/]+/, window.location.origin);
        }
      } catch (e) {
        console.error('[Domain Isolation] Early loader error:', e);
      }
    }
    return window.__domainIsolationOriginals.open.apply(this, [method, url, ...args]);
  };
  
  console.log('[Domain Isolation] Early domain isolation initialized');
})();