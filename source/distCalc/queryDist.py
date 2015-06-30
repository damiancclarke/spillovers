# queryDist.py v1.10             damiancclarke             yyyy-mm-dd:2015-06-22
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# This script queries the distance (driven) between all input areas on a map. It
# outputs a file with one line per distance between each point of the input file
# along with the time taken to drive.
# 
# This script queries google's matrix distance API and requires an API code.  To
# request an API code and for further details, a manual is available at the fol-
# lowing address:
#
#    https://developers.google.com/maps/documentation/distancematrix/
#
# This version of the script has been applied to Chile, where searches are made
# on a regional basis.  Google's API for map distances has a 2500 per day limit
# on searches, however ~25,000 searches must be made to find all combinations of
# interest.  In order to get around this, various API keys have been created, w-
# hich permits all queries to be sent in the same 24 hour period.  However, these
# API keys will only work once per day. If the script needs to be run multiple t-
# imes, the APIkeys variable should be repopulated with new keys available at the
# above url.
#
# Contact: damian.clarke@economics.ox.ac.uk

import urllib2
import json 
import sys  

reload(sys)  
sys.setdefaultencoding('utf8')

areas = open('comunas.csv', 'r')
pills = open('pillComunas.csv', 'r')
res   = open('distances.csv', 'w')

query = {'r1': '',
         'r2': '',
         'r3': '',
         'r4': '',
         'r5': '',
         'r6': '',
         'r7': '',
         'r8': '',
         'r9': '',
         'r10': '',
         'r11': '',
         'r12': '',
         'r13': '',
         'r14': '',
         'r15': ''
}
names  = []
codes  = []

#-------------------------------------------------------------------------------
#--- (1a) Generate full comuna list
#-------------------------------------------------------------------------------
for i,line in enumerate(areas):
    if i>0:
        line = line.replace('\n','')
        area = line.split(',')[0]
        code = line.split(',')[1]

        names.append(area)
        codes.append(str(code))

#-------------------------------------------------------------------------------
#--- (1b) Generate search list by region
#-------------------------------------------------------------------------------
for i,line in enumerate(pills):
    if i>0:
        line = line.replace('\n','')

        area = line.split(',')[1].replace(' ', '+')
        code = line.split(',')[3]
        regn = line.split(',')[4]
        name = 'r'+regn

        query[name] += area +'+Chile|' 


#-------------------------------------------------------------------------------
#--- (2a) Set up splits to work around 2500 query limit on map API
#-------------------------------------------------------------------------------
Rsearch = [[], [1,15,2], [2,1,3], [3,2,4], [4,3,5], [5,4,13], [6,13,7], [7,6,8],
           [8,7,9],[9,8,14], [10,14], [10,12], [12,10], [13,5],[14,9,10],[15,1]]
nsearch = 0
APIkeys = ['AIzaSyCo92tYxn-nyt3rXuazOOPpH4N5d0P7pTA',
           'AIzaSyCxOmsvSpqMsZH6rjxvRTDPq6-y_csE2hg',
           'AIzaSyBC3x9m3xK0l-_3ZLwMlI991n0-LBKOWcg',
           'AIzaSyA9_ZwFBo8Eul_mPZu23zmaX1HAX9t_5V8',
           'AIzaSyCaHIVailoXBR9uRcvBPmDbWkr7kYkViCo',
           'AIzaSyDqi_itJZD6mhRMTTo9PLX4VwK7VHjLDtQ',
           'AIzaSyBvXtIWipDcfJX9t00vowNPQviJ00aAhm0',
           'AIzaSyA9e2XNxe7m7lopwoq_ArvP0-CbyT6Lmig',
           'AIzaSyC0s2IzqwERFkbNsUvUAiTrq73y0lC4enM',
           'AIzaSyC2XMO9y5BZxfvKYLf7k4Q75q1HATl-TOA',
           'AIzaSyB_hj3xkdO_LskCBhF0OTS5v-u1WgCHrGg'
]


url1 = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins='
url2 = '&destinations='
url3 = '&language=en-US&key='

title = 'Origin;Code;Destination;Distance;Dist (units);Duration;Dur (units)\n'
res.write(title)

#-------------------------------------------------------------------------------
#--- (2b) Find distance between each Comuna and each other Comuna
#-------------------------------------------------------------------------------
for i,incom in enumerate(names):
    lineint = incom + ';' + codes[i]
    Rcode = int(float(codes[i])/1000)

    add1 = incom.replace(' ','+')+'+CHILE'
    if add1 == 'COLCHANE+CHILE':
        add1 = 'CARIQUIMA+CHILE'

    for region in Rsearch[Rcode]:
        rname = 'r'+str(region)
        Qlist = query[rname].split('|')[0:-1]

        for j in Qlist:
            nsearch = nsearch + 1

        multiple2500 = nsearch / 2500
        key = APIkeys[multiple2500]
 
        result = urllib2.urlopen(url1+add1+url2+query[rname]+url3+key).read()
        result = json.loads(result)


        for i,outcom in enumerate(result["destination_addresses"]):
            outN = Qlist[i].replace('+Chile','') 
            outN = outN.replace('+',' ') 

            try:
                dsT = result['rows'][0]['elements'][i]['distance']['text']
                dsN = str(result['rows'][0]['elements'][i]['distance']['value'])
            except:
                dsT = 'NA'
                dsN = 'NA'
            try:
                duT = result['rows'][0]['elements'][i]['duration']['text']
                duN = str(result['rows'][0]['elements'][i]['duration']['value'])
            except:
                duT = 'NA'
                duN = 'NA'

            newline=lineint+';'+outN+';'+dsT+';'+dsN+';'+duT+';'+duN+'\n' 
            print newline
            res.write(newline)
res.close()
