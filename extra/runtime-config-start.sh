#!/bin/bash
echo "Generating runtime configuration..."
mkdir -p /app/web/public

# Generate runtime config
cat > /app/web/public/runtime-config.js << EOF
window.RUNTIME_CONFIG = {
  LEARNHOUSE_API_URL: "${NEXT_PUBLIC_LEARNHOUSE_API_URL:-}",
  LEARNHOUSE_BACKEND_URL: "${NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL:-}",
  LEARNHOUSE_DOMAIN: "${NEXT_PUBLIC_LEARNHOUSE_DOMAIN:-}",
  LEARNHOUSE_DEFAULT_ORG: "${NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG:-default}",
  LEARNHOUSE_MULTI_ORG: "${NEXT_PUBLIC_LEARNHOUSE_MULTI_ORG:-false}",
  LEARNHOUSE_TOP_DOMAIN: "${NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN:-}"
}
EOF

# Copy the pre-created isolation scripts to the public folder
cp /app/extra/api-interceptor.js /app/web/public/
cp /app/extra/api-response-sanitizer.js /app/web/public/
cp /app/extra/domain-isolation-loader.js /app/web/public/

echo "Runtime configuration generated successfully"

echo "Enhanced patching of NextAuth cookies and domains..."
find /app/web/.next -type f -name "*.js" -exec sed -i "s/domain:[^,}]*,/domain: undefined,/g" {} \;
find /app/web/.next -type f -name "*.js" -exec sed -i "s/domain: *process.env.LEARNHOUSE_COOKIE_DOMAIN/domain: undefined/g" {} \;
find /app/web/.next -type f -name "*.js" -exec sed -i "s/\.domain\s*=\s*[^;]*;/\.domain = undefined;/g" {} \;
echo "Cookie domain patches complete."

echo "Starting application..."
sh /app/start.sh