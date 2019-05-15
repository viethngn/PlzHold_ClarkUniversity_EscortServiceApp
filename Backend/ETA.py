import requests
import json
import sys

#Google Maps API Key
api_key = 'AIzaSyAoqZOqkR2jc1X5JAaA3MYeAUWBhK7Xlq0'

#source
#source_ex = '42.2520,-71.8234'
source = sys.argv[1]

#destination
#dest_ex = '42.2595,-71.8261'
dest = sys.argv[2]

# url variable store url  
url ='https://maps.googleapis.com/maps/api/distancematrix/json?'
 

def getETA(source, dest, current_waittime: 0):
	# Get method of requests module 
	# return response object 
	r = requests.get(url + 'origins=' + source + '&destinations=' + dest + '&key=' + api_key) 
                     
	# json method of response object 
	# return json format result 
	eta_sec = int(r.json()['rows'][0]['elements'][0]['duration']['value']) + current_waittime
	eta_min = r.json()['rows'][0]['elements'][0]['duration']['text'] + current_waittime
	# bydefault driving mode considered 
  
	# print the vale of x 
	print(eta_min)
	sys.stdout.flush()
	return eta_sec

#vanLocations is a tuple containing location of the 4 vans: ['van1Lat,van1Long', ...'van4Lat,van4Long']
#capacity is a tuple containing the capacity of the 4 vans: [van1cap, ...van4cap]
def getVanETA(vanLocations, capacity):
	vanPicked = capacity.index(min(capacity))
	vanETA = getETA(vanLocations[vanPicked], source)
	return (vanPicked, vanETA)

def main ():
	getETA(source, dest)

if __name__ == '__main__':
	main()