from threading import Thread
from dotenv import load_dotenv
from flask import Flask
import time
import datetime
import random
import os

load_dotenv()
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

print(os.environ.get('SKYREAL_API_KEY'))

class RealTimeMaster:
    def __init__(self):
        self.currentRealTime = random_timestamp()
        self.thread = Thread(target=self.update, args=())
        self.thread.daemon = True
        self.thread.start()
    def getRealTime(self):
        return self.currentRealTime
    def update(self):
        while True:
            # If currentRealTime is over
            if self.currentRealTime < time.time():
                self.currentRealTime = random_timestamp()
                print("UPDATE")
                
            readableCurrentRealTime = datetime.datetime.fromtimestamp(self.currentRealTime)
            print("Current Real Time: " + str(readableCurrentRealTime))
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

if __name__ == '__main__':
      app.run(host='0.0.0.0', port=80)
