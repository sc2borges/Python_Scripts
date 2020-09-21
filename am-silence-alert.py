import sys,os
import argparse
import requests, json
import time
from datetime import datetime, timedelta


# Set Variables
base_url = "http://localhost:8080"
api_path = "/api/v1/silences"


def option_menu():

    parser = argparse.ArgumentParser(description='This program Silence AlertManager Alerts through CLI parameters.')
    parser.add_argument('-l', '--hours' , type=int, default=0, metavar='',
                        help='Define number of hours to silence AM.')
    parser.add_argument('-m', '--minutes', type=int, default=15, metavar='',
                        help='Set the Minutes range to Silence an Alert.')
    parser.add_argument('-s', '--service',type=str, default='Match_Service', metavar='',
                        help='Define which service will be included on this Silence.')
    parser.add_argument('-o', '--owner', type=str, default='Owner', metavar='',
                        help='Set the Owner for this Silence Alert.')
    parser.add_argument('-c', '--comments', type=str, default='No-Comments-were-set-here.', metavar='',
                        help='Define Silence Alert Comments.')
    cli_args = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit()

    silence_alert(cli_args.hours,cli_args.minutes, cli_args.owner, cli_args.service, cli_args.comments)

def silence_alert(hours,minutes,owner,service,comments):


  set_hour = hours
  set_min = minutes
  service_name = service
  createdBy = owner
  comment = comments

# ISO8601 format
# timestr = datetime_var.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"

#   now = datetime.now()
  now = datetime.utcnow()

  format = "%Y-%m-%dT%H:%M:%S.%f"  #e.g  2018-10-25T22:12:33.533330795Z

  current_time = now.strftime(format)[:-3] + "Z"

  silence_time = now + timedelta(hours=set_hour, minutes=set_min)

  silence_end = silence_time.strftime(format)[:-3] + "Z"

  url =  base_url + api_path
  headers = {'Content-Type':'application/json'}
  payload = { "matchers":
             [
                {
                    "name": service_name,
                    "value": ".*"
                }
              ],
              "startsAt": current_time ,
              "endsAt": silence_end ,
              "createdBy": createdBy,
              "comment": comment ,
              "status": {
                  "state": "active"
                }
             }

  api_response = requests.post(url , data=json.dumps(payload), headers=headers)

  if (' ' in service_name )== True:
        print( "Service should not have spaces - status: %s"  %  str(api_response.reason) )
  elif api_response.status_code != 200:
       print("Error to Silence service: " + service_name  + " Status Code: " + str(api_response.status_code) )
  else:
       print( "Silence created at: " +  current_time )

def main ():
    option_menu()

if __name__ == "__main__":
   main()
