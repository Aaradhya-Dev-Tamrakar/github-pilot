from pilot.config import AccountConfig, PilotConfig

def test_account_config():
    acc = AccountConfig(username="TestUser", token="ghp_test123")
    assert acc.username == "TestUser"
    assert acc.has_auth is True
    headers = acc.get_auth_headers()
    assert "Authorization" in headers
    assert headers["Authorization"] == "Bearer ghp_test123"

def test_account_config_unauthenticated():
    acc = AccountConfig(username="TestUserNoAuth")
    assert acc.has_auth is False
    headers = acc.get_auth_headers()
    assert "Authorization" not in headers

def test_pilot_config_defaults():
    config = PilotConfig()
    assert config.primary_account.username is not None
    assert config.cache_ttl_seconds > 0
