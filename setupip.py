import os, subprocess
from xml.dom.minidom import parseString

def findXmlSection(dom, sectionName):
   sections = dom.getElementsByTagName(sectionName)
   return sections[0]

def getPropertyMap(ovfEnv):
   dom = parseString(ovfEnv)
   section = findXmlSection(dom, "PropertySection")
   propertyMap = {}
   for property in section.getElementsByTagName("Property"):
      key   = property.getAttribute("oe:key")
      value = property.getAttribute("oe:value")
      propertyMap[key] = value
   dom.unlink()
   return propertyMap
 
enc = sys.stdout.encoding
if subsystem.check_output(["C:\\Program Files\\VMware\\VMware Tools\\vmtoolsd.exe", "--cmd" ,"info-get guestinfo.ovfEnv"], shell=True) == 0:
    ovfEnv = subsystem.check_output(["C:\\Program Files\\VMware\\VMware Tools\\vmtoolsd.exe", "--cmd" ,"info-get guestinfo.ovfEnv"], shell=True).decode(enc)
else:
    ovfEnv = open("d:\\ovf-env.xml", "r").read()

propertyMap = getPropertyMap(ovfEnv)

ip      = propertyMap["ip"]
netmask = propertyMap["netmask"]
gateway = propertyMap["gateway"]
dns1    = propertyMap["dns1"]
dns2    = propertyMap["dns2"]

# Get only first ethernet adapter name
name = subprocess.check_output("wmic nic where `"netconnectionid like '%'\" get netconnectionid", shell=True).decode(enc)
name = "\"" + str(name).split('\r\r\n')[1].strip() + "\""

# Set up IP
os.system("netsh interface ip set address %s static %s %s %s 0" % (name, ip, netmask, gateway))

# Set up preferred DNS server
os.system("netsh interface ip set dns %s static %s" % (name, dns1))

# Set up alternate DNS server
os.system("netsh interface ip add dns %s %s index=2" % (name, dns2)) 
