import os
import sys
import requests
import json


data = '{ "matchers": [ { "name": "alername1", "value": ".*" } ], "startsAt": "2020/09/18T15:45:58.856Z", "endsAt": "2020/09/18T18:00:58.856Z", "createdBy": "api", "comment": "Silence", "status": { "state": "active" } }'
# data = {'matchers': [{'name': 'alername1', 'value': '.*'}], 'startsAt': '2020/09/17T01:15:10.172Z', 'endsAt': '2020/09/17T03:30:10.172Z', 'createdBy': 'service', 'comment': 'Silence', 'status': {'state': 'active'}}
# data =  {"matchers": [{"name": "alername1", "value": ".*"}], "startsAt": "2020/09/18T15:45:58.856Z", "endsAt": "2020/09/18T18:00:58.856Z", "createdBy": "service", "comment": "Silence", "status": {"state": "active"}}

print(data)
# response = requests.post('http://localhost:8080/api/v1/silences', data=json.dumps(data))
response = requests.get('http://localhost:8080/api/v1/silences')
print(response.reason)



# curl http://localhost:8080/api/v1/silences -d '{
#       "matchers": [
#         {
#           "name": "alername1",
#           "value": ".*",
#           "isRegex": false
#         }
#       ],
#       "startsAt": "2020-09-16T12:25:29.956Z",
#       "endsAt": "2020-09-16T14:25:29.956Z",
#       "createdBy": "api",
#       "comment": "Silence",
#       "status": {
#         "state": "active"
#       }
# }'
