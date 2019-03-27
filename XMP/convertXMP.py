#! /usr/bin/python

# NOTE: reference: http://www.exiv2.org/tags-xmp-crs.html for a list of keys

from libxmp import XMPMeta

# open the XMP file and parse
with open('sample_sidecar.xmp', 'r') as fptr:
    strbuffer = fptr.read()
xmp = XMPMeta()
xmp.parse_from_str(strbuffer)

#print (xmp)

XMP_NS_CAMERA_RAW="http://ns.adobe.com/camera-raw-settings/1.0/"

print ("crs:PresetType = {}".format(xmp.get_property(XMP_NS_CAMERA_RAW, "PresetType")))
