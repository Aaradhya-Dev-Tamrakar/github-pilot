import os
from pathlib import Path
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from dotenv import load_dotenv

# Automatically load local .env if present
load_dotenv()

class AccountConfig(BaseModel):
    username: str
    token: Optional[str] = None

    @property
    def has_auth(self) -> bool:
        return bool(self.token and self.token.strip())

    def get_auth_headers(self) -> Dict[str, str]:
        headers = {
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "GitHub-Pilot-Agent"
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token.strip()}"
        return headers


class PilotConfig(BaseModel):
    primary_account: AccountConfig = Field(
        default_factory=lambda: AccountConfig(
            username=os.getenv("GITHUB_PRIMARY_USER", "Aaradhya-Dev-Tamrakar"),
            token=os.getenv("GITHUB_PRIMARY_TOKEN")
        )
    )
    secondary_account: AccountConfig = Field(
        default_factory=lambda: AccountConfig(
            username=os.getenv("GITHUB_SECONDARY_USER", "AaradhyaDT"),
            token=os.getenv("GITHUB_SECONDARY_TOKEN")
        )
    )
    cache_dir: Path = Field(
        default_factory=lambda: Path(os.getenv("PILOT_CACHE_DIR", ".cache/pilot"))
    )
    cache_ttl_seconds: int = Field(
        default_factory=lambda: int(os.getenv("PILOT_CACHE_TTL_SECONDS", "21600"))
    )
    scraper_user_agent: str = Field(
        default_factory=lambda: os.getenv(
            "PILOT_SCRAPER_USER_AGENT",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
        )
    )

    def ensure_cache_dirs(self) -> None:
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        (self.cache_dir / "scraper").mkdir(parents=True, exist_ok=True)
        (self.cache_dir / "audit").mkdir(parents=True, exist_ok=True)


_config_instance: Optional[PilotConfig] = None

def get_config() -> PilotConfig:
    global _config_instance
    if _config_instance is None:
        _config_instance = PilotConfig()
        _config_instance.ensure_cache_dirs()
    return _config_instance
