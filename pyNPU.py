#!/usr/bin/env python3

# for exiting etc
import sys
# used for command line argument parsing
import argparse
# for creating the checksum based on hmac key
import hashlib
import hmac
# used to get data from Sony servers
import requests
# use lxml for CDATA parsing
from lxml import etree as xml
from lxml import html

# return codes
# 0 - success
# 1 - user errors
# 2 - no update available

# hmac key from http://wololo.net/talk/viewtopic.php?f=54&t=44091
# thank you Proxima
key = bytes.fromhex("E5E278AA1EE34082A088279C83F9BBC806821C52F2AB5D2B4ABD995450355114")

program_version = "0.0.1"
## script parameter handling
parser = argparse.ArgumentParser(prog='pyNPU', usage='%(prog)s [options]')
parser.add_argument('--changelog', '-c', action='store_true', help="Print changelog to stdout")
parser.add_argument('--bbcode', '-b', action='store_true', help="Change changelog to format to BB Code")
parser.add_argument('--link', '-l', action='store_true', help="Print download link of the latest update")
parser.add_argument('--name', '-n', action='store_true', help="Print the name of the game (same as in the sfo)")
parser.add_argument('--all', '-a', action='store_true', help="Print all updates available")
parser.add_argument('--title-id', '-t', nargs=1, help="specify the Title ID of game")
parser.add_argument('--version', '-v', action='version', version='%(prog)s v0.0.1')
args = parser.parse_args()

if not args.title_id:
    print("Error: No Title ID given.")
    sys.exit(1)
else:
    title = args.title_id[0]

# create the checksum for the url
hmac_sha256 = hmac.new(key, msg=("np_" + title).encode('utf-8'), digestmod=hashlib.sha256).hexdigest()

# create url from title id and checksum
update_url = "http://gs-sec.ww.np.dl.playstation.net/pl/np/%s/%s/%s-ver.xml" % (title, hmac_sha256, title)

# get the request
r = requests.get(update_url, verify=False)
if r.status_code == 404:
    print("No update for this game available")
    sys.exit(2)
r.close()

try:
    xml.fromstring(r.content)
except:
    print("No update for this game available")
    sys.exit(2)

# get python object from XML
update_xml = xml.fromstring(r.content)

# make sure several arguments cannot be combined
if args.changelog and args.link:
    print('Error: Cannot combine parameter "changelog" and "link"')
    sys.exit(1)
elif args.changelog and args.all:
    print('Error: Cannot combine parameter "changelog" and "all"')
    sys.exit(1)
elif args.bbcode and args.link:
    print('Error: Cannot combine parameter "bbcode" and "link"')
    sys.exit(1)
elif args.name and (args.link or args.changelog or args.bbcode or args.all):
    print('Error: Cannot combine parameter "name" with others except "title-id"')
    sys.exit(1)
elif args.bbcode and not args.changelog:
    print('Error: Cannot use parameter "bbcode" without "changelog"')
    sys.exit(1)

# not sure if the if the check is really needed
if update_xml.get('status') == "alive":
    # get changelog
    if args.changelog:
        # get the url for the changelog and download it into change_url
        for changeinfo in update_xml.iter('changeinfo'):
            change_url = changeinfo.get('url')
        r = requests.get(change_url)

        ### create xml parser and make sure CDATA won't be stripped
        xmlparser = xml.XMLParser(strip_cdata=False)
        changelog_xml = xml.XML(r.content, xmlparser)
        r.close()

        for version in changelog_xml:
            # output simple bbcodes
            if args.bbcode:
                print('== ' + version.get('app_ver') + ' ==')
                # parse content into a html object and iterate of all elements in html body
                for element in html.document_fromstring(version.text.replace('\t','')).body.getchildren():
                    if element.tag == 'b':
                        print('[b]' + element.text_content() + '[/b]')
                    elif element.tag == 'ul':
                        for list in element.getchildren():
                            print("[*] " + list.text_content())
                    elif element.tag == 'li':
                        print("[*] " + element.text_content())
                    elif element.tag == 'p':
                        print(element.text_content())
            else:
                print(version.get('app_ver'))
                # parse content into a html object and iterate of all elements in html body
                for element in html.document_fromstring(version.text.replace('\t','')).body.getchildren():
                    if element.tag == 'b':
                        print(element.text_content())
                    elif element.tag == 'ul':
                        for list in element.getchildren():
                            print("- " + list.text_content())
                    elif element.tag == 'li':
                        print("- " + element.text_content())
                    elif element.tag == 'p':
                        print(element.text_content())
    elif args.link:
        if args.all:
            for package in update_xml.iter('package'):
                # check if element has 'hybrid_package' as children
                if package.find('hybrid_package') is not None:
                    for subpackage in package:
                # print hybrid_package link when available
                        if subpackage.tag == 'hybrid_package':
                            print(subpackage.get('url'))
                else:
                    print(package.get('url'))
        else:
            for package in update_xml.iter('package'):
                if 'version' not in locals():
                    version = float(package.get('version'))
                else:
                    if version < float(package.get('version')):
                        version = float(package.get('version'))

            for package in update_xml.iter('package'):
                if float(package.get('version')) == version:
                    # check if element has 'hybrid_package' as children
                    if package.find('hybrid_package') is not None:
                        for subpackage in package:
                            # print hybrid_package link when available
                            if subpackage.tag == 'hybrid_package':
                                print(subpackage.get('url'))
                    else:
                        print(package.get('url'))
    elif args.name:
        for name in update_xml.iter('title'):
            print(name.text)
