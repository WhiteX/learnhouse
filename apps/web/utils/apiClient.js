import { getApiUrl } from './runtimeConfig';

/**
 * Creates an API client that uses runtime configuration
 * @returns {Object} API client object with fetch method
 */
export function createApiClient() {
  return {
    /**
     * Fetch data from the API with the correct runtime URL
     * @param {string} path - API path to fetch from
     * @param {Object} options - Fetch options
     * @returns {Promise<any>} - JSON response
     */
    fetch: async (path, options = {}) => {
      const url = getApiUrl(path);
      console.log(`[API] Fetching from: ${url}`);
      
      const response = await fetch(url, options);
      
      if (!response.ok) {
        throw new Error(`API request failed: ${response.status}`);
      }
      
      return response.json();
    },
    
    /**
     * Post data to the API with the correct runtime URL
     * @param {string} path - API path to post to
     * @param {Object} data - Data to post
     * @param {Object} options - Additional fetch options
     * @returns {Promise<any>} - JSON response
     */
    post: async (path, data, options = {}) => {
      const url = getApiUrl(path);
      console.log(`[API] Posting to: ${url}`);
      
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...options.headers,
        },
        body: JSON.stringify(data),
        ...options,
      });
      
      if (!response.ok) {
        throw new Error(`API request failed: ${response.status}`);
      }
      
      return response.json();
    }
  };
}

// Create a singleton instance for easier imports
export const apiClient = createApiClient();