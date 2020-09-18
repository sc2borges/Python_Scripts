import sys,os
import argparse
import requests, json
from datetime import datetime, timedelta


# Set Variables
base_url = "http://localhost:8080"
api_path = "/api/v1/silences"




class color:
   PURPLE = '\033[95m'
   CYAN = '\033[96m'
   DARKCYAN = '\033[36m'
   BLUE = '\033[94m'
   GREEN = '\033[92m'
   YELLOW = '\033[93m'
   RED = '\033[91m'
   BOLD = '\033[1m'
   UNDERLINE = '\033[4m'
   END = '\033[0m'

def silence_alert():

  service_name = str(sys.argv[1])
  set_hour = int(sys.argv[2])
  set_min = int(sys.argv[3])

# ISO8601 format
# timestr = datetime_var.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"

  now = datetime.now()

  format = "%Y-%m-%dT%H:%M:%S.%f"  #e.g  2018-10-25T22:12:33.533330795Z

  current_time = now.strftime(format)[:-3] + "Z"

  silence_time = now + timedelta(hours=set_hour , minutes=set_min)

  silence_end = silence_time.strftime(format)[:-3] + "Z"

  url =  base_url+ api_path
  headers = {'Content-Type':'application/json'}
  payload = { "matchers":
             [
                {
                    "name": "alername1",
                    "value": ".*"
                }
              ],
              "startsAt": current_time ,
              "endsAt": silence_end ,
              "createdBy": service_name,
              "comment": "Silence",
              "status": {
                  "state": "active"
                }
             }

  api_response = requests.post(url , data=json.dumps(payload), headers=headers)
  if api_response.status_code == 200:
        print( color.GREEN + "Silence created at: " +  current_time + color.END )
        # print(api_response)
  else:
        print("Error to Silence service: " + color.GREEN + color.BOLD + service_name + color.END + " Status Code: " + color.RED + str(api_response.status_code) + color.END  )


def main ():

    # if len(sys.argv) > 4:
    #   print('You have specified too many arguments')
    #   sys.exit()

    # if len(sys.argv) < 3:
    #   print('You need to specify the path to be listed')
    #   sys.exit()

    silence_alert()


if __name__ == "__main__":
   main()
