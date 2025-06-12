import uvicorn
import os
# import logfire
from fastapi import FastAPI, Request
from config.config import LearnHouseConfig, get_learnhouse_config
from src.core.events.events import shutdown_app, startup_app
from src.router import v1_router
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi_jwt_auth.exceptions import AuthJWTException
from fastapi.middleware.gzip import GZipMiddleware


# from src.services.mocks.initial import create_initial_data

########################
# Pre-Alpha Version 0.1.0
# Author: @swve
# (c) LearnHouse 2022
########################

# Get LearnHouse Config
learnhouse_config: LearnHouseConfig = get_learnhouse_config()

# Debug logging for deployment isolation
print(f"🔍 DEPLOYMENT DEBUG INFO:")
print(f"   DEPLOYMENT_NAME: {os.environ.get('DEPLOYMENT_NAME', 'NOT_SET')}")
print(f"   DATABASE: {learnhouse_config.database_config.sql_connection_string[:50]}...")
print(f"   REDIS: {learnhouse_config.redis_config.redis_connection_string[:50]}...")
print(f"   COOKIE_DOMAIN: {learnhouse_config.hosting_config.cookie_config.domain}")
print(f"   API_DOMAIN: {learnhouse_config.hosting_config.domain}")
print(f"🔍 END DEBUG INFO")

# Global Config
app = FastAPI(
    title=learnhouse_config.site_name,
    description=learnhouse_config.site_description,
    docs_url="/docs" if learnhouse_config.general_config.development_mode else None,
    redoc_url="/redoc" if learnhouse_config.general_config.development_mode else None,
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=learnhouse_config.hosting_config.allowed_regexp,
    allow_methods=["*"],
    allow_credentials=True,
    allow_headers=["*"],
)

# LogFire Configuration - Disable for SQLAlchemy
# logfire.configure(console=False, service_name=learnhouse_config.site_name,)
# logfire.instrument_fastapi(app)

# Gzip Middleware (will add brotli later)
app.add_middleware(GZipMiddleware, minimum_size=1000)


# Events
app.add_event_handler("startup", startup_app(app))
app.add_event_handler("shutdown", shutdown_app(app))


# JWT Exception Handler
@app.exception_handler(AuthJWTException)
def authjwt_exception_handler(request: Request, exc: AuthJWTException):
    return JSONResponse(
        status_code=exc.status_code,  # type: ignore
        content={"detail": exc.message},  # type: ignore
    )


# Static Files
app.mount("/content", StaticFiles(directory="content"), name="content")

# Global Routes
app.include_router(v1_router)


if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=learnhouse_config.hosting_config.port,
        reload=learnhouse_config.general_config.development_mode,
    )


# General Routes
@app.get("/")
async def root():
    return {"Message": "Welcome to LearnHouse ✨"}

# Debug endpoint for deployment verification
@app.get("/debug/deployment")
async def debug_deployment():
    import os
    return {
        "deployment_name": os.environ.get('DEPLOYMENT_NAME', 'NOT_SET'),
        "cookie_domain": learnhouse_config.hosting_config.cookie_config.domain,
        "api_domain": learnhouse_config.hosting_config.domain,
        "database_host": learnhouse_config.database_config.sql_connection_string.split('@')[1].split('/')[0] if '@' in learnhouse_config.database_config.sql_connection_string else "unknown",
        "redis_host": learnhouse_config.redis_config.redis_connection_string.split('@')[1].split(':')[0] if '@' in learnhouse_config.redis_config.redis_connection_string else "unknown"
    }
