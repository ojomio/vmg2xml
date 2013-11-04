#!/usr/bin/env python

import quopri,re, StringIO, datetime, calendar, locale
from optparse import OptionParser

buf = StringIO

Regexp = { 'CellNumber' : re.compile(r'CELL:(\+[0-9]*)\r'),
    'Date': re.compile(r'^Date:(.*)\r'),
    'Body_1st_line': re.compile(r'TEXT.*PRINTABLE:(.*)\r$'),
    'Body_others_lines': re.compile(r'(.*)\r') }
Date_conversion = re.compile(r'(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2}):(\d{2})')

# Setting locale to FR_fr for correct date formating
locale.setlocale(locale.LC_ALL, 'fr_FR')

def extractor(field='', line='', sms_items={}):
    '''
    Extract a field from VMG file using a dictionnary of regexp
    Special process to Body that may be on several line
    '''
    if field.startswith('Body'):
        dict_field = 'Body'
    else:
        dict_field = field
        
    try:
       sms_items[dict_field] += re.search(Regexp[field], line).group(1)
#       print "Found " + dict_field + ": " + sms_items[dict_field]
    except AttributeError:
       pass
    return sms_items

def format_date(all_sms):
    '''
    Just split date and time components retrieved from VMG file, and 
    use them to construct a datetime object then replace old Date entry
    in dict variable.
    '''
    for sms in all_sms:
        match = re.search(Date_conversion, sms['Date'])
        sms['Date'] = datetime.datetime(int(match.group(3)), int(match.group(2)), int(match.group(1)), int(match.group(4)), int(match.group(5)), int(match.group(6)))
    return all_sms
        
def construct_listing(infile):
    '''
    Function list all sms into a vmg file and for each one
    add an entry to a list variable. Currently, script find
    and store 3 informations from VMG file : Cell Number, Date
    and message itself.
    '''
    all_sms = []
    sms_items = {'CellNumber': '', 'Date': '', 'Body': ''}
    Body_Complete = False

    for line in infile.readlines():
        sms_items = extractor('CellNumber', line, sms_items)
        sms_items = extractor('Date', line, sms_items)
        sms_items = extractor('Body_1st_line', line, sms_items)
        if not line.startswith('END:VBODY') and (not line.startswith('TEXT;') and sms_items['Body'] != ''):
            sms_items['Body'] = sms_items['Body'].rstrip('=')
            sms_items = extractor('Body_others_lines', line, sms_items)
        elif line.startswith('END:VBODY'):
            sms_items['Body'] = re.sub(r'=0A', ' ', sms_items['Body'])
            sms_items['Body'] = quopri.decodestring(sms_items['Body'])
            Body_Complete = True

        # Populate sms list when all informations retrieved and reset information for next sms
        if sms_items['CellNumber'] != '' and sms_items['Date'] != '' and Body_Complete == True:
            all_sms.append(sms_items)
            sms_items = { 'CellNumber': '', 'Date': '', 'Body': ''}
            Body_Complete = False
    return all_sms

def write_output(outfile, all_sms=[]):
    '''
    Just write in SMS Backup Restore xml file format the result
    VMG file parsing.
    '''
    header = "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\n<!--File Created By SMS Backup & Restore v6.41 on 02/11/2013 17:54:18-->\n<?xml-stylesheet type=\"text/xsl\" href=\"sms.xsl\"?>\n<smses count=\""+ str(len(all_sms)) + "\">\n"
    footer = "</smses>"
    file_handler = open(outfile, mode='w')
    file_handler.write(header)
    
    for sms in all_sms:
        # Added 000 to include milliseconds into timestamp.
        timestamp = str(calendar.timegm(sms['Date'].timetuple())) + "000"
        line = '<sms protocol="0" address="' + sms['CellNumber'] + '" date="' + timestamp + '" type="1" subject="null" body="' + sms['Body'] + '" toa="null" sc_toa="null" service_center="+33660003000" read="1" status="-1" locked="0" date_sent="' + timestamp + '", readable_date="' + sms['Date'].strftime("%d %b %Y %H:%M:%S")  + '" />\n'
        file_handler.write(line)

    file_handler.write(footer)
    file_handler.close()
    print "All SMS convert into XML format for SMS Backup Restore Android app"

def main(inputfile, outputfile):
    infile = open(inputfile)
    print "Going find our sms !"
    all_sms = construct_listing(infile)
    infile.close()
    print "Found", len(all_sms), "SMS."
    all_sms = format_date(all_sms)
    write_output(outputfile, all_sms)

if __name__ == "__main__":
    parser = OptionParser()
    parser.add_option('-i', '--inputfile', dest='inputfile', help='vmg file to convert')
    parser.add_option('-o', '--outputfile', dest='outputfile', help='xml file result of conversion.')

    options, args = parser.parse_args()
    main(**options.__dict__)
