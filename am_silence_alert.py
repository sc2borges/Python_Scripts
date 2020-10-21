#! /usr/bin/env python3
import sys
import os
import argparse
import requests
import json
from datetime import datetime, timedelta


# Set Variables
base_url = "http://localhost:8080"
api_path = "/api/v1/silences"

def silence_alert(minutes,creator,service,am_filter,comments):

  now = datetime.utcnow()

  format = "%Y-%m-%dT%H:%M:%S.%f"  #e.g  2018-10-25T22:12:33.533330795Z

  current_time = now.strftime(format)[:-3] + "Z"

  silence_time = now + timedelta(minutes=minutes)

  silence_end = silence_time.strftime(format)[:-3] + "Z"

  url =  base_url + api_path
  headers = {'Content-Type':'application/json'}
  payload = { "matchers":
             [
                {
                    "name": service,
                    "value": am_filter
                }
              ],
              "startsAt": current_time ,
              "endsAt": silence_end ,
              "createdBy": creator,
              "comment": comments ,
              "status": {
                  "state": "active"
                }
             }

  if (' ' in service ) == True:
       print( "Service should not have spaces ")
  else:
       api_response = requests.post(url , data=json.dumps(payload), headers=headers)
       print( f"Silence created at: {current_time} ")
    #    print(api_response["data"])
       get_SID = api_response.json()
       os.environ['SID'] = get_SID['data']['silenceId']
    #    os.putenv('MYSID', '$SID')
       print(os.environ)
    #    print(api_response.json(["{data:'silenceId'}"]))

def main ():

    parser = argparse.ArgumentParser(description='This program Silence AlertManager Alerts through CLI parameters.')
    parser.add_argument('-m', '--minutes', type=int, default=15, metavar='',
                        help='Set the Minutes range to Silence an Alert.')
    parser.add_argument('-s', '--service',type=str, default='Match_Service', metavar='',
                        help='Define which service will be included on this Silence.')
    parser.add_argument('-f', '--am_filter',type=str, default='-*', metavar='',
                        help='Define which filters need to be included for service Silence.')
    parser.add_argument('-o', '--creator', type=str, default='not set', metavar='',
                        help='Set the Creator for this Silence Alert.')
    parser.add_argument('-c', '--comments', type=str, default='No-Comments-were-set-here.', metavar='',
                        help='Define Silence Alert Comments.')
    cli_args = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit()

    silence_alert(cli_args.minutes, cli_args.creator, cli_args.service, cli_args.am_filter, cli_args.comments)

if __name__ == "__main__":
   main()
