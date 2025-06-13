/**
 * API Response Sanitizer
 * 
 * This script specifically handles API responses to ensure they don't contain
 * URLs pointing to the wrong domain.
 */
(function() {
  console.log('[Domain Isolation] Installing API response sanitizer...');
  
  // Save reference to the original fetch
  const originalFetch = window.fetch;

  /**
   * Recursively sanitize objects to replace URLs from wrong domains
   */
  function sanitizeObject(obj, currentDomain) {
    if (!obj || typeof obj !== 'object') return obj;
    
    // Handle arrays
    if (Array.isArray(obj)) {
      return obj.map(item => sanitizeObject(item, currentDomain));
    }
    
    // Handle objects
    const result = {};
    
    for (const [key, value] of Object.entries(obj)) {
      // Check if this is a URL string value
      if (typeof value === 'string' && 
          (value.startsWith('http://') || value.startsWith('https://'))) {
        try {
          const url = new URL(value);
          if (url.hostname !== currentDomain && 
              !url.hostname.includes('api-gateway.umami.dev')) {
            console.log(`[Sanitizer] Found cross-domain URL: ${value}`);
            const newValue = value.replace(url.hostname, currentDomain);
            result[key] = newValue;
            continue;
          }
        } catch (e) {
          // Not a valid URL, keep original value
        }
      }
      
      // Process nested objects/arrays
      if (value && typeof value === 'object') {
        result[key] = sanitizeObject(value, currentDomain);
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }
  
  // Override fetch to sanitize responses
  window.fetch = async function(...args) {
    const currentDomain = window.location.hostname;
    
    // Call original fetch
    const response = await originalFetch.apply(this, args);
    
    // Clone the response so we can read it multiple times
    const clonedResponse = response.clone();
    
    // Only process JSON responses from API endpoints
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json') && 
        (args[0].includes('/api/') || args[0].includes('api/v1'))) {
      
      try {
        // Read and parse the response
        const originalData = await clonedResponse.json();
        
        // Sanitize the data
        const sanitizedData = sanitizeObject(originalData, currentDomain);
        
        // Create a new response with sanitized data
        return new Response(JSON.stringify(sanitizedData), {
          status: response.status,
          statusText: response.statusText,
          headers: response.headers
        });
      } catch (e) {
        console.error('[Domain Isolation] Error sanitizing response:', e);
        return response; // Return original response on error
      }
    }
    
    return response;
  };
  
  console.log('[Domain Isolation] API response sanitizer installed');
})();