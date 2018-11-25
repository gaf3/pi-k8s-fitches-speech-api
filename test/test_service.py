import unittest
import unittest.mock

import os
import json

import service

class MockRedis(object):

    def __init__(self, host, port):

        self.host = host
        self.port = port
        self.channel = None

        self.messages = []

    def publish(self, channel, message):

        self.channel = channel
        self.messages.append(message)

class TestService(unittest.TestCase):

    @unittest.mock.patch.dict(os.environ, {
        "REDIS_HOST": "data.com",
        "REDIS_PORT": "667",
        "REDIS_CHANNEL": "stuff"
    })
    @unittest.mock.patch("redis.StrictRedis", MockRedis)
    def setUp(self):

        self.apx = service.api()
        self.api = self.apx.app.test_client()

    def test_health(self):

        self.assertEqual(self.api.get("/health").json, {"message": "OK"})

    @unittest.mock.patch("service.time.time")
    def test_speak(self, mock_time):

        mock_time.return_value = 7

        self.assertEqual(self.api.post("/speak", json={
            "text": "hi",
            "language": "en"
        }).json, {
            "message": {
                "timestamp": 7,
                "text": "hi",
                "language": "en"
            }
        })
        self.assertEqual(self.apx.redis.channel, "stuff")
        self.assertEqual(json.loads(self.apx.redis.messages[0]), {
            "timestamp": 7,
            "text": "hi",
            "language": "en"
        })

        self.assertEqual(self.api.post("/speak", json={
            "text": "there",
            "node": "bump",
            "language": "en"
        }).json, {
            "message": {
                "timestamp": 7,
                "node": "bump",
                "text": "there",
                "language": "en"
            }
        })
        self.assertEqual(json.loads(self.apx.redis.messages[1]), {
            "timestamp": 7,
            "node": "bump",
            "text": "there",
            "language": "en"
        })
