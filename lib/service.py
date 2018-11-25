import os
import time
import json
import redis
import connexion

apx = None

def api():

    import service

    service.apx = connexion.App("service", specification_dir='/opt/pi-k8s/openapi')
    service.apx.add_api('service.yaml')

    service.apx.redis = redis.StrictRedis(host=os.environ['REDIS_HOST'], port=int(os.environ['REDIS_PORT']))
    service.apx.channel = os.environ['REDIS_CHANNEL']

    return service.apx

def health():

    return {"message": "OK"}

def speak():

    message = {
        "timestamp": time.time(),
        "text": connexion.request.json["text"],
        "language": connexion.request.json["language"]
    }

    if "node" in connexion.request.json:
        message["node"] = connexion.request.json["node"]

    apx.redis.publish(apx.channel, json.dumps(message))

    return {"message": message}, 202