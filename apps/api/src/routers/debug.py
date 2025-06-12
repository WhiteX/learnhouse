import os
from fastapi import APIRouter
from config.config import get_learnhouse_config

router = APIRouter()

@router.get("/deployment")
async def debug_deployment():
    """Debug endpoint for deployment verification and isolation testing"""
    learnhouse_config = get_learnhouse_config()
    
    return {
        "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'NOT_SET'),
        "cookie_domain": learnhouse_config.hosting_config.cookie_config.domain,
        "api_domain": learnhouse_config.hosting_config.domain,
        "database_host": learnhouse_config.database_config.sql_connection_string.split('@')[1].split('/')[0] if '@' in learnhouse_config.database_config.sql_connection_string else "unknown",
        "redis_host": learnhouse_config.redis_config.redis_connection_string.split('@')[1].split(':')[0] if '@' in learnhouse_config.redis_config.redis_connection_string else "unknown"
    }
