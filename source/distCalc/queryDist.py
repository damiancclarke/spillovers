# queryDist.py                   damiancclarke             yyyy-mm-dd:2015-06-22
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

import urllib2
import json 
import sys  

reload(sys)  
sys.setdefaultencoding('utf8')


areas = open('comunas.csv', 'r')
pills = open('pillComunas.csv', 'r')

res   = open('distances.csv', 'w')

query1 = ''
query2 = ''
query3 = ''
query4 = ''
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

"""
#-------------------------------------------------------------------------------
#--- (2) Find distance between each comuna and each other Comuna
#-------------------------------------------------------------------------------
url1 = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins='
url2 = '&destinations='
url3 = '&language=en-US&key='
APIk = 'AIzaSyBZaiSKZ6rRbp-HYXL5UKCWM3Uq2hlLsr8'

title = 'Origin;Destination;Distance;Distance (units);Duration;Duration (units)\n'
print title
res.write(title)

for i,incom in enumerate(names):
    lineint = incom + ';' + codes[i]

    add1 = incom.replace(' ','+')+'CHILE'
    if add1 == 'COLCHANE+CHILE':
        add1 = 'CARIQUIMA+CHILE'

    for query in [query1,query2,query3,query4]:
        Qlist = query.split('|')

        result = urllib2.urlopen(url1+add1+url2+query+url3+APIk).read()
        result = json.loads(result)


        for i,outcom in enumerate(result["destination_addresses"]):
            outN = Qlist[i].replace('+Chile','') 
            outN = outN.replace('+',' ') 

            try:
                distT = result['rows'][0]['elements'][i]['distance']['text']
                distN = str(result['rows'][0]['elements'][i]['distance']['value'])
            except:
                distT = 'NA'
                distN = 'NA'
            try:
                duraT = result['rows'][0]['elements'][i]['duration']['text']
                duraN = str(result['rows'][0]['elements'][i]['duration']['value'])
            except:
                duraT = 'NA'
                duraN = 'NA'

            newline=lineint+';'+outN+';'+distT+';'+distN+';'+duraT+';'+duraN+'\n' 
            print newline
            res.write(newline)


res.close()
"""
