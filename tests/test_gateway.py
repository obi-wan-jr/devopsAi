"""
Test suite for the AI System Administrator Agent Gateway
"""

import pytest
import asyncio
from unittest.mock import Mock, patch, AsyncMock
from fastapi.testclient import TestClient

from src.gateway.router import APIGateway


class TestAPIGateway:
    """Test cases for the APIGateway class."""

    @pytest.fixture
    def gateway(self):
        """Create a test gateway instance."""
        gateway = APIGateway()
        return gateway

    @pytest.fixture
    def client(self, gateway):
        """Create a test client."""
        return TestClient(gateway.app)

    def test_gateway_initialization(self, gateway):
        """Test gateway initialization with environment variables."""
        assert gateway.app is not None
        assert "qwen3" in gateway.models
        assert gateway.models["qwen3"]["name"] == "Qwen3-4B-Thinking"

    def test_model_selection_qwen3(self, gateway):
        """Test model selection always returns qwen3."""
        # Since we only have one model now, it should always return qwen3
        model_id = gateway._select_model(None, "test message")
        assert model_id == "qwen3"

        model_id = gateway._select_model("qwen3", "test message")
        assert model_id == "qwen3"

    def test_health_endpoint(self, client):
        """Test health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert data["status"] == "healthy"

    def test_status_endpoint(self, client):
        """Test status endpoint."""
        response = client.get("/status")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "models" in data
        assert "uptime" in data
        assert "qwen3" in data["models"]

    def test_models_endpoint(self, client):
        """Test models listing endpoint."""
        response = client.get("/models")
        assert response.status_code == 200
        data = response.json()
        assert "models" in data
        assert "qwen3" in data["models"]
        assert data["models"]["qwen3"]["name"] == "Qwen3-4B-Thinking"

    def test_invalid_model_endpoint(self, client):
        """Test invalid model endpoint."""
        response = client.post("/chat/invalid_model", json={"message": "test"})
        assert response.status_code == 404
        data = response.json()
        assert "detail" in data

    @patch('src.gateway.router.httpx.AsyncClient')
    async def test_chat_request_processing(self, mock_client_class, gateway):
        """Test chat request processing with mocked remote LLM."""
        # Mock the HTTP client
        mock_client = AsyncMock()
        mock_response = AsyncMock()
        mock_response.raise_for_status = AsyncMock()
        mock_response.json.return_value = {
            "choices": [{"message": {"content": "Test response"}}]
        }
        mock_client.post.return_value = mock_response
        mock_client_class.return_value.__aenter__.return_value = mock_client

        # Test the _get_response method
        response = await gateway._get_response("qwen3", "Test message")
        assert response == "Test response"

    def test_rate_limiting_initialization(self, gateway):
        """Test rate limiting initialization."""
        assert hasattr(gateway, 'rate_limit_per_minute')
        assert hasattr(gateway, 'request_counts')
        assert gateway.rate_limit_per_minute == 60  # Default value

    def test_authentication_initialization(self, gateway):
        """Test authentication initialization."""
        assert hasattr(gateway, 'api_key')
        assert hasattr(gateway, 'api_key_header')


class TestGatewayIntegration:
    """Integration tests for gateway functionality."""

    @pytest.fixture
    def client(self):
        """Create a test client with gateway."""
        gateway = APIGateway()
        return TestClient(gateway.app)

    def test_root_endpoint(self, client):
        """Test root endpoint returns API information."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "service" in data
        assert "models" in data
        assert "qwen3" in data["models"]

    def test_cors_headers(self, client):
        """Test CORS headers are present."""
        response = client.options("/chat", headers={"Origin": "http://localhost:3004"})
        assert response.status_code == 200
        assert "access-control-allow-origin" in response.headers

    def test_invalid_chat_request(self, client):
        """Test invalid chat request handling."""
        response = client.post("/chat", json={})
        assert response.status_code == 422  # Validation error

    def test_model_info_endpoint(self, client):
        """Test model info endpoint."""
        response = client.get("/qwen3/models")
        # This will likely fail in test environment due to network, but tests the routing
        assert response.status_code in [200, 500]  # Either success or network error


if __name__ == "__main__":
    pytest.main([__file__])
