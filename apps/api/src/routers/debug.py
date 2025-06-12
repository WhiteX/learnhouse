import os
import subprocess
from fastapi import APIRouter, Request
from config.config import get_learnhouse_config

router = APIRouter()

@router.get("/deployment")
async def debug_deployment():
    """Debug endpoint for deployment verification and isolation testing"""
    learnhouse_config = get_learnhouse_config()
    
    # Parse database host safely
    db_host = "unknown"
    if '@' in learnhouse_config.database_config.sql_connection_string:
        try:
            parts = learnhouse_config.database_config.sql_connection_string.split('@')
            if len(parts) > 1:
                host_parts = parts[1].split('/')
                if len(host_parts) > 0:
                    db_host = host_parts[0]
        except Exception:
            pass
    
    # Parse redis host safely
    redis_host = "unknown"
    if '@' in learnhouse_config.redis_config.redis_connection_string:
        try:
            parts = learnhouse_config.redis_config.redis_connection_string.split('@')
            if len(parts) > 1:
                host_parts = parts[1].split(':')
                if len(host_parts) > 0:
                    redis_host = host_parts[0]
        except Exception:
            pass
    
    return {
        "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'NOT_SET'),
        "cookie_domain": learnhouse_config.hosting_config.cookie_config.domain,
        "api_domain": learnhouse_config.hosting_config.domain,
        "database_host": db_host,
        "redis_host": redis_host,
        "database_name": learnhouse_config.database_config.sql_connection_string.split('/')[-1] if '/' in learnhouse_config.database_config.sql_connection_string else "unknown",
        "env_vars": {
            "NEXT_PUBLIC_LEARNHOUSE_DOMAIN": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_DOMAIN', 'NOT_SET'),
            "NEXT_PUBLIC_LEARNHOUSE_API_URL": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_API_URL', 'NOT_SET')
        }
    }

@router.get("/urls")
async def debug_urls(request: Request):
    """Debug endpoint to detect hardcoded URLs in NextJS bundle"""
    try:
        # This only works if Next.js files are accessible from the API container
        result = subprocess.run(
            ["find", "/app/web/.next", "-type", "f", "-name", "*.js", "-exec", "grep", "-o", "http://edu.adradviser.ro[^\"']*", "{}", ";"],
            capture_output=True, text=True, timeout=5
        )
        hardcoded_urls = list(set(result.stdout.strip().split('\n'))) if result.stdout.strip() else []
        
        # Get the current domain for comparison
        current_domain = os.environ.get('NEXT_PUBLIC_LEARNHOUSE_DOMAIN', 'unknown')
        
        return {
            "detected_hardcoded_urls": hardcoded_urls,
            "current_domain": current_domain,
            "client_host": request.client.host,
            "headers": dict(request.headers),
            "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'NOT_SET')
        }
    except Exception as e:
        return {
            "error": str(e),
            "message": "Could not scan for hardcoded URLs",
            "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'NOT_SET')
        }
