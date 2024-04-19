#!/usr/bin/env python

import requests
import time

# The API endpoint
url = "http://localhost:8080/rolldice"

try:
	while True:

		# A GET request to the API
		response = requests.get(url)

		# Print the response
		response_json = response.json()
		print(response_json)
		time.sleep(1)
except KeyboardInterrupt:
	pass
finally:
		print("All done")