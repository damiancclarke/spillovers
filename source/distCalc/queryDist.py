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

nmin = 0
nmax = 100

areas = open('comunas.csv', 'r')
pills = open('pillComunas.csv', 'r')
if nmin==0:
    res   = open('distances.csv', 'w')
else:
    res   = open('distances.csv', 'a')


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

print query['r10']

#-------------------------------------------------------------------------------
#--- (2) Find distance between each comuna and each other Comuna
#-------------------------------------------------------------------------------
Rsearch = [[], [1,15,2], [2,1,3], [3,2,4], [4,3,5], [5,4,13], [6,13,7], [7,6,8],
           [8,7,9], [9,8,14], [10,14], [10,12], [12,10], [13,5], [14,9,10], [15,1]]
nsearch = 0

url1 = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins='
url2 = '&destinations='
url3 = '&language=en-US&key='
APIk = 'AIzaSyBZaiSKZ6rRbp-HYXL5UKCWM3Uq2hlLsr8'

title = 'Origin;Code;Destination;Distance;Dist (units);Duration;Dur (units)\n'
print title
res.write(title)


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

        if nsearch >= nmin and nsearch < nmax:
            result = urllib2.urlopen(url1+add1+url2+query[rname]+url3+APIk).read()
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

