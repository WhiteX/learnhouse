import os
import json
import socket
import subprocess
from fastapi import APIRouter, Request, Response
from config.config import get_learnhouse_config

router = APIRouter()

@router.get("/deployment")
async def debug_deployment():
    """Debug endpoint for deployment verification and isolation testing"""
    learnhouse_config = get_learnhouse_config()
    
    # Parse database host safely
    db_host = "unknown"
    db_user = "unknown"
    db_name = "unknown"
    if '@' in learnhouse_config.database_config.sql_connection_string:
        try:
            # Split out username and host parts
            auth_host_parts = learnhouse_config.database_config.sql_connection_string.split('@')
            if len(auth_host_parts) > 1:
                # Extract username
                auth_parts = auth_host_parts[0].split('//')
                if len(auth_parts) > 1:
                    user_parts = auth_parts[1].split(':')
                    if len(user_parts) > 0:
                        db_user = user_parts[0]
                
                # Extract host and database name
                host_parts = auth_host_parts[1].split('/')
                if len(host_parts) > 0:
                    db_host = host_parts[0]
                if len(host_parts) > 1:
                    db_name = host_parts[1]
        except Exception as e:
            pass
    
    # Parse redis host safely
    redis_host = "unknown"
    redis_db = "unknown"
    if '@' in learnhouse_config.redis_config.redis_connection_string:
        try:
            parts = learnhouse_config.redis_config.redis_connection_string.split('@')
            if len(parts) > 1:
                host_parts = parts[1].split(':')
                if len(host_parts) > 0:
                    redis_host = host_parts[0]
                if len(host_parts) > 1 and '/' in host_parts[1]:
                    redis_db = host_parts[1].split('/')[1]
        except Exception:
            pass
    
    # Get hostname information
    hostname = "unknown"
    try:
        hostname = socket.gethostname()
    except:
        pass
    
    # Get process and container info
    container_id = "unknown"
    try:
        # Try to get container ID from cgroup
        with open('/proc/self/cgroup', 'r') as f:
            for line in f:
                if 'docker' in line:
                    container_id = line.strip().split('/')[-1]
                    break
    except:
        pass
    
    return {
        "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'NOT_SET'),
        "hostname": hostname,
        "container_id": container_id,
        "cookie_domain": learnhouse_config.hosting_config.cookie_config.domain,
        "api_domain": learnhouse_config.hosting_config.domain,
        "database": {
            "host": db_host,
            "user": db_user,
            "name": db_name,
        },
        "redis": {
            "host": redis_host,
            "db": redis_db
        },
        "env_vars": {
            "NEXT_PUBLIC_LEARNHOUSE_DOMAIN": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_DOMAIN', 'NOT_SET'),
            "NEXT_PUBLIC_LEARNHOUSE_API_URL": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_API_URL', 'NOT_SET'),
            "NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN', 'NOT_SET'),
            "LEARNHOUSE_COOKIE_DOMAIN": os.environ.get('LEARNHOUSE_COOKIE_DOMAIN', 'NOT_SET')
        }
    }

@router.get("/urls")
async def debug_urls(request: Request):
    """Debug endpoint to detect hardcoded URLs in NextJS bundle"""
    try:
        # Define domains to check for hardcoding
        known_domains = [
            "edu.adradviser.ro",  # LIVE domain
            "adr-lms.whitex.cloud"  # DEV domain
        ]
        
        # Add any additional domains from environment variables
        current_domain = os.environ.get('NEXT_PUBLIC_LEARNHOUSE_DOMAIN', '')
        if current_domain and current_domain not in known_domains:
            known_domains.append(current_domain)
        
        # Build patterns for all domains to detect cross-contamination
        patterns = []
        for domain in known_domains:
            patterns.extend([
                f"http://{domain}[^\"']*",
                f"https://{domain}[^\"']*",
                f"//{domain}[^\"']*",
                f"'{domain}'",
                f"\"{domain}\"",
                f"fetch\\(\"https://{domain}",
                f"fetch\\(\"http://{domain}",
            ])
        
        # Add general patterns for NextAuth configuration
        patterns.extend([
            "\"/api/auth/session\"",
            "\"auth/session\"",
            "fetch\\(\"/api/auth",
            "domain:\"[^\"]*\"",
            "baseUrl:\"[^\"]*\"",
            "basePath:\"[^\"]*\"",
            "NEXTAUTH_URL=\"[^\"]*\"",
            "NEXTAUTH_URL='[^']*'"
        ])
        
        all_urls = []
        domain_matches = {domain: [] for domain in known_domains}
        
        # Search for URLs in JS files
        for pattern in patterns:
            result = subprocess.run(
                ["find", "/app/web/.next", "-type", "f", "-name", "*.js", "-exec", "grep", "-o", pattern, "{}", ";"],
                capture_output=True, text=True, timeout=10
            )
            if result.stdout.strip():
                found_urls = list(set(result.stdout.strip().split('\n')))
                all_urls.extend(found_urls)
                
                # Categorize URLs by domain
                for url in found_urls:
                    for domain in known_domains:
                        if domain in url:
                            domain_matches[domain].append(url)
        
        # Look for NextAuth configuration
        auth_configs = []
        try:
            auth_result = subprocess.run(
                ["find", "/app/web/.next", "-type", "f", "-name", "*.js", "-exec", "grep", "-o", "NEXTAUTH_URL[^,}]*", "{}", ";"],
                capture_output=True, text=True, timeout=5
            )
            if auth_result.stdout.strip():
                auth_configs = list(set(auth_result.stdout.strip().split('\n')))
        except Exception:
            pass
        
        # Gather environment variable information
        env_vars = {
            "NEXT_PUBLIC_LEARNHOUSE_DOMAIN": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_DOMAIN', 'NOT_SET'),
            "NEXT_PUBLIC_LEARNHOUSE_API_URL": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_API_URL', 'NOT_SET'),
            "NEXT_PUBLIC_API_URL": os.environ.get('NEXT_PUBLIC_API_URL', 'NOT_SET'),
            "NEXTAUTH_URL": os.environ.get('NEXTAUTH_URL', 'NOT_SET'),
            "NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN', 'NOT_SET'),
            "LEARNHOUSE_COOKIE_DOMAIN": os.environ.get('LEARNHOUSE_COOKIE_DOMAIN', 'NOT_SET')
        }
        
        # Get the top domain from an environment variable or extract from current domain
        top_domain = os.environ.get('NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN', '')
        if not top_domain and current_domain:
            parts = current_domain.split('.')
            if len(parts) >= 2:
                top_domain = '.'.join(parts[-2:])
            
        return {
            "detected_hardcoded_urls": all_urls,
            "domain_specific_matches": domain_matches,
            "nextauth_configs": auth_configs,
            "current_domain": current_domain,
            "top_domain": top_domain,
            "env_vars": env_vars,
            "client_host": request.client.host,
            "headers": dict(request.headers),
            "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'NOT_SET'),
            "request_url": str(request.url)
        }
    except Exception as e:
        return {
            "error": str(e),
            "message": "Could not scan for hardcoded URLs",
            "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'NOT_SET')
        }

@router.get("/cookies")
async def debug_cookies(request: Request, response: Response):
    """Debug endpoint to test cookie isolation and behavior"""
    # Get current configuration
    learnhouse_config = get_learnhouse_config()
    cookie_domain = learnhouse_config.hosting_config.cookie_config.domain
    deployment_name = os.environ.get('DEPLOYMENT_NAME', 'unknown')
    
    # Set a test cookie with the current configuration
    response.set_cookie(
        key=f"isolation-test-{deployment_name}",
        value=deployment_name,
        domain=cookie_domain,
        httponly=True,
        samesite="lax",
        path="/"
    )
    
    # Try to read any existing isolation test cookies
    cookies = request.cookies
    isolation_cookies = {}
    
    for key, value in cookies.items():
        if key.startswith("isolation-test-"):
            isolation_cookies[key] = value
    
    return {
        "deployment_name": deployment_name,
        "cookie_domain": cookie_domain,
        "request_host": request.headers.get("host", "unknown"),
        "detected_isolation_cookies": isolation_cookies,
        "all_cookies": {k: "****" if not k.startswith("isolation-test") else v for k, v in cookies.items()},
        "top_domain": os.environ.get('NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN', 'NOT_SET'),
        "message": f"Set test cookie 'isolation-test-{deployment_name}={deployment_name}' with domain={cookie_domain}"
    }

@router.get("/session")
async def debug_session(request: Request):
    """Debug endpoint to check session-related headers and environment variables"""
    # Extract host information
    host = request.headers.get("host", "unknown")
    origin = request.headers.get("origin", "unknown")
    referer = request.headers.get("referer", "unknown")
    
    # Extract NextAuth related information
    nextauth_url = os.environ.get('NEXTAUTH_URL', 'NOT_SET')
    nextauth_url_internal = os.environ.get('NEXTAUTH_URL_INTERNAL', 'NOT_SET')
    
    # Check if session requests would go to the correct place
    session_destination = nextauth_url or f"https://{host}"
    
    return {
        "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'unknown'),
        "request_headers": {
            "host": host,
            "origin": origin,
            "referer": referer,
        },
        "session_config": {
            "NEXTAUTH_URL": nextauth_url,
            "NEXTAUTH_URL_INTERNAL": nextauth_url_internal,
            "detected_session_destination": session_destination
        },
        "cookie_domain": get_learnhouse_config().hosting_config.cookie_config.domain,
        "message": "This endpoint helps diagnose where NextAuth session data would be sent"
    }
