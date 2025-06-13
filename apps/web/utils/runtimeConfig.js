/**
 * Utility functions to access runtime configuration values
 */

/**
 * Gets configuration from runtime values (window.RUNTIME_CONFIG) with fallback to environment variables
 * This ensures dynamic configuration at runtime instead of build time
 */
export function useRuntimeConfig() {
  // For server-side rendering, use environment variables
  if (typeof window === 'undefined') {
    return {
      apiUrl: process.env.NEXT_PUBLIC_LEARNHOUSE_API_URL,
      backendUrl: process.env.NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL,
      domain: process.env.NEXT_PUBLIC_LEARNHOUSE_DOMAIN,
      defaultOrg: process.env.NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG || 'default',
      multiOrg: process.env.NEXT_PUBLIC_LEARNHOUSE_MULTI_ORG === 'true',
      topDomain: process.env.NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN
    };
  }
  
  // For client-side, prioritize runtime config over baked-in environment variables
  const config = window.RUNTIME_CONFIG || {};
  return {
    apiUrl: config.LEARNHOUSE_API_URL || process.env.NEXT_PUBLIC_LEARNHOUSE_API_URL,
    backendUrl: config.LEARNHOUSE_BACKEND_URL || process.env.NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL,
    domain: config.LEARNHOUSE_DOMAIN || process.env.NEXT_PUBLIC_LEARNHOUSE_DOMAIN,
    defaultOrg: config.LEARNHOUSE_DEFAULT_ORG || process.env.NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG || 'default',
    multiOrg: config.LEARNHOUSE_MULTI_ORG === 'true' || process.env.NEXT_PUBLIC_LEARNHOUSE_MULTI_ORG === 'true',
    topDomain: config.LEARNHOUSE_TOP_DOMAIN || process.env.NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN
  };
}

/**
 * Gets the API URL with the correct domain
 * @param {string} path - The API path
 * @returns {string} - The complete API URL
 */
export function getApiUrl(path) {
  const config = useRuntimeConfig();
  return `${config.apiUrl || `https://${config.domain}/api/v1/`}${path}`;
}

/**
 * Gets the backend URL with the correct domain
 * @param {string} path - The backend path
 * @returns {string} - The complete backend URL
 */
export function getBackendUrl(path) {
  const config = useRuntimeConfig();
  return `${config.backendUrl || `https://${config.domain}/`}${path}`;
}