import pytest
import json
import sys
from unittest.mock import Mock, patch

import read_bme280 as sensor_module


# --- Fixtures ---
@pytest.fixture
def mock_bme280():
    """Create a mock BME280 sensor."""
    mock = Mock()
    mock.temperature = 22.5
    mock.relative_humidity = 45.0
    return mock


@pytest.fixture
def auth_params():
    """Standard auth parameters."""
    return {"username": "test_user", "password": "test_pass"}


# --- Critical Tests ---
class TestSensorReading:
    """Core sensor reading tests."""
    
    @patch('time.time', return_value=1234567890.123)
    def test_get_sensor_reading(self, mock_time, mock_bme280):
        """Test sensor reading returns correct data."""
        reading = sensor_module.get_sensor_reading(mock_bme280)
        
        assert reading['ts'] == 1234567890123.0
        assert reading['temperature'] == 22.5
        assert reading['humidity'] == 45.0


class TestMQTTPublishing:
    """Core MQTT publishing tests."""
    
    @patch('paho.mqtt.publish.single')
    @patch('time.time', return_value=1000.0)
    def test_publish_single_reading(self, mock_time, mock_mqtt, mock_bme280, auth_params):
        """Test MQTT publish with correct payload."""
        sensor_module.publish_single_reading(
            mock_bme280,
            auth_params,
            hostname="test.mqtt.com",
            port=1883,
            topic="test/topic"
        )
        
        call_kwargs = mock_mqtt.call_args[1]
        payload = json.loads(call_kwargs['payload'])
        
        assert call_kwargs['hostname'] == "test.mqtt.com"
        assert call_kwargs['topic'] == "test/topic"
        assert payload['temperature'] == 22.5
        assert payload['humidity'] == 45.0
    
    @patch('paho.mqtt.publish.single')
    def test_publish_failure_raises_runtime_error(self, mock_mqtt, mock_bme280, auth_params):
        """Test MQTT failure handling."""
        mock_mqtt.side_effect = Exception("Connection failed")
        
        with pytest.raises(RuntimeError, match="MQTT publish failed"):
            sensor_module.publish_single_reading(mock_bme280, auth_params)


class TestPublishingLoop:
    """Core loop tests."""
    
    @patch('read_bme280.publish_single_reading')
    @patch('read_bme280.print_reading')
    @patch('time.sleep')
    def test_publish_loop_iterations(self, mock_sleep, mock_publish, 
                                     mock_bme280, auth_params):
        """Test loop executes correct number of times."""
        sensor_module.publish_readings(
            auth_params,
            mock_bme280,
            freq=2,
            max_iterations=3
        )
        
        assert mock_publish.call_count == 3
        mock_sleep.assert_called_with(30.0)  # 60/2 = 30 seconds
    
    @pytest.mark.parametrize("invalid_freq", [0, 61, -1])
    def test_invalid_frequency_raises_error(self, mock_bme280, auth_params, invalid_freq):
        """Test frequency validation."""
        with pytest.raises(ValueError, match="Frequency must be between 1 and 60"):
            sensor_module.publish_readings(auth_params, mock_bme280, freq=invalid_freq)
    
    @patch('time.sleep')
    @patch('read_bme280.publish_single_reading')
    @patch('read_bme280.print_reading')
    @patch('read_bme280.logger')  # Mock logger to avoid log output
    def test_loop_continues_after_error(self, mock_logger, mock_print, mock_publish, 
                                        mock_sleep, mock_bme280, auth_params):
        """Test loop continues despite failures."""
        mock_publish.side_effect = RuntimeError("Test error")
    
        # Should NOT raise - errors are caught and logged
        sensor_module.publish_readings(auth_params, mock_bme280, max_iterations=3)
        
        # All 3 iterations should attempt to publish
        assert mock_publish.call_count == 3
        
        # Verify errors were logged
        assert mock_logger.error.call_count == 3

class TestConfiguration:
    """Core configuration tests."""
    
    @patch.dict('os.environ', {'MQTT_USER': 'user', 'MQTT_PASSWORD': 'pass'}, clear=True)
    @patch('read_bme280.load_dotenv')
    def test_load_auth_success(self, mock_load_dotenv):
        """Test loading auth from environment."""
        auth = sensor_module.load_auth_from_env()
        
        assert auth['username'] == 'user'
        assert auth['password'] == 'pass'  # type: ignore
    
    @patch.dict('os.environ', {}, clear=True)
    @patch('read_bme280.load_dotenv')
    def test_load_auth_missing_credentials(self, mock_load_dotenv):
        """Test error when credentials missing."""
        with pytest.raises(ValueError, match="MQTT_USER"):
            sensor_module.load_auth_from_env()


class TestSensorInit:
    """Core sensor initialization tests."""
    
    @patch('board.I2C')
    @patch('adafruit_bme280.basic.Adafruit_BME280_I2C')
    def test_init_sensor_success(self, mock_bme_class, mock_i2c):
        """Test successful sensor initialization."""
        mock_sensor = Mock()
        mock_bme_class.return_value = mock_sensor
        
        sensor = sensor_module.init_sensor()
        
        assert sensor.sea_level_pressure == 1013.25
        mock_i2c.assert_called_once()
    
    @patch('board.I2C')
    def test_init_sensor_failure(self, mock_i2c):
        """Test sensor init failure handling."""
        mock_i2c.side_effect = Exception("I2C error")
        
        with pytest.raises(RuntimeError, match="Sensor initialization failed"):
            sensor_module.init_sensor()


class TestMain:
    """Core main function test."""
    
    @patch('read_bme280.publish_readings')
    @patch('read_bme280.init_sensor')
    @patch('read_bme280.load_auth_from_env')
    @patch('read_bme280.parse_args')
    def test_main_integration(self, mock_parse, mock_auth, mock_init, mock_publish):
        """Test main function wires everything together."""
        mock_args = Mock(hostname='test', freq=5, port=1883, topic='test/topic')
        mock_parse.return_value = mock_args
        mock_auth.return_value = {'username': 'user', 'password': 'pass'}
        mock_sensor = Mock()
        mock_init.return_value = mock_sensor
        
        sensor_module.main()
        
        mock_publish.assert_called_once_with(
            bme280=mock_sensor,
            hostname='test',
            freq=5,
            auth={'username': 'user', 'password': 'pass'},
            port=1883,
            topic='test/topic'
        )