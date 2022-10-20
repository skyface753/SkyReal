from threading import Thread
from flask import Flask
import time
import datetime
import random
import os
import redis
import dotenv

dotenv.load_dotenv()
onesignalAppId = os.getenv("ONESIGNAL_APP_ID")
onesignalRestApiKey = os.getenv("ONESIGNAL_REST_API_KEY")

print("ONESIGNAL_APP_ID: ", onesignalAppId)
print("ONESIGNAL_REST_API_KEY: ", onesignalRestApiKey)

from onesignal_sdk.client import Client

onesignalClient = Client(app_id=onesignalAppId, rest_api_key=onesignalRestApiKey)

notification_body = {
    'contents': {'tr': 'Yeni bildirim', 'en': 'Time for SkyReal'},
    'included_segments': ['Subscribed Users'],
}


redisClient = redis.Redis(host='localhost', port=6379, db=0)

# Randrom Timestamp between tomorrow 10am and 12:59:59pm
def random_timestamp():
    start = (datetime.datetime.today() + datetime.timedelta(days=1)).replace(hour=10, minute=0, second=0, microsecond=0)
    end = (datetime.datetime.today() + datetime.timedelta(days=1)).replace(hour=23, minute=59, second=59, microsecond=0)
    startTimestamp = time.mktime(start.timetuple())
    endTimestamp = time.mktime(end.timetuple())
    # DEV -> 10 seconds
    # start = datetime.datetime.today()
    # end = datetime.datetime.today() + datetime.timedelta(seconds=10)
    # startTimestamp = time.mktime(start.timetuple())
    # endTimestamp = time.mktime(end.timetuple())
    return startTimestamp + (endTimestamp - startTimestamp) * random.random()


class RealTimeMaster:
    def __init__(self):
        self.currentRealTime = random_timestamp()
        self.thread = Thread(target=self.update, args=())
        self.thread.daemon = True
        self.printCounter = 0
        self.thread.start()
    def getRealTime(self):
        return self.currentRealTime
    def update(self):
        while True:
            # If currentRealTime is over
            if self.currentRealTime < time.time():
                redisClient.set('lastRealTimestamp', self.currentRealTime)
                print("UPDATE")
                self.currentRealTime = random_timestamp()
                response = onesignalClient.send_notification(notification_body)
                print('Notification send', response.body)                
            readableCurrentRealTime = datetime.datetime.fromtimestamp(self.currentRealTime)
            if self.printCounter % 10 == 0:
                print("Next Real Time: " + str(readableCurrentRealTime))
            self.printCounter += 1
            time.sleep(1)


realTimeMaster = RealTimeMaster()

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "Hello, World!"

# /GET /api/master/realtime
@app.route("/api/master/realtime")
def getRealTime():
    return str(realTimeMaster.getRealTime())

@app.route("/api/master/realtime/setNow")
def setRealTimeNow():
    realTimeMaster.currentRealTime = time.time()
    return "Set Real Time to Now"

if __name__ == '__main__':
      app.run(host='0.0.0.0', port=80)
