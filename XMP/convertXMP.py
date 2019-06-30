#! /usr/bin/python

# Script to convert a Photoshop/Lightroom XMP preset into the equivalent JSON data for use with phixer.

# NOTE: reference: http://www.exiv2.org/tags-xmp-crs.html for a list of keys
#                  https://www.spacetelescope.org/static/projects/python-xmp-toolkit/docs/reference.html for XMPMeta APIs

# Also note that the preset keys changed in 2012 so sometimes you have to check for both the old (they have "2012" in the name) and the new
# Many preset XMP files include settings with zero values, so we gnerally check for that and don't apply the corresponding filter if no changes are made
# - this is because creating and running a filter takes a lot of memory and sometimes they have an effect even with 'zero' parameters

import os, os.path
import errno

from libxmp import XMPMeta, XMPIterator, utils
from scipy.interpolate import UnivariateSpline
import numpy as np
import json
import argparse


XMP_NS_CAMERA_RAW="http://ns.adobe.com/camera-raw-settings/1.0/"

#TEMP: hardcoded files for testing
infile = 'sample_sidecar.xmp'
outfile = 'sample_preset.json'


# XMP Metatdata
xmp = XMPMeta()


# map holding the various filter parameters
filterMap = {}

# there are several ways to change the tone curve, so make it global and have each method build on any previous changes
# default is a linear tomne curve:
toneCurve = [ [0.0, 0.0], [25.0, 25.0], [50.0, 50.0], [75.0, 75.0], [100.0, 100.0]]

# flag to indicate that ToneCurve shoud be added (modified by several different processes)
toneCurveChanged = False


'''
    red = UIColor(red: 0.901961, green: 0.270588, blue: 0.270588, alpha: 1) hsv: [0.0, 0.7, 0.886806]
    orange = UIColor(red: 0.901961, green: 0.584314, blue: 0.270588, alpha: 1) hsv: [30.0/360.0, 0.7, 0.886806]
    yellow = UIColor(red: 0.901961, green: 0.901961, blue: 0.270588, alpha: 1) hsv: [60.0/360.0, 0.7, 0.901961]
    green = UIColor(red: 0.270588, green: 0.901961, blue: 0.270588, alpha: 1) hsv: [120.0/360.0, 0.7, 0.901961]
    aqua = UIColor(red: 0.270588, green: 0.901961, blue: 0.901961, alpha: 1) hsv: [180.0/360.0, 0.7, 0.901961]
    blue = UIColor(red: 0.270588, green: 0.270588, blue: 0.901961, alpha: 1) hsv: [240.0/360.0, 0.7, 0.901961]
    purple = UIColor(red: 0.584314, green: 0.270588, blue: 0.901961, alpha: 1) hsv: [270.0/360.0, 0.7, 0.901961]
    magenta = UIColor(red: 0.901961, green: 0.270588, blue: 0.901961, alpha: 1) hsv: [300.0/360.0, 0.7, 0.901961]
'''

# the set of reference colours
refColour = {"red": [0.0, 0.7, 0.886806], "orange": [0.083333, 0.7, 0.901961], "yellow": [0.166666, 0.7, 0.901961], "green": [0.333333, 0.7, 0.901961],
             "aqua": [0.5, 0.7, 0.901961], "blue": [0.666666, 0.7, 0.901961], "purple": [0.75, 0.7, 0.901961], "magenta": [0.833333, 0.7, 0.901961] }
'''
# the HSV colour vectors. This can change
colourVectors = {"red": [0.0, 0.7, 0.886806], "orange": [0.083333, 0.7, 0.901961], "yellow": [0.166666, 0.7, 0.901961], "green": [0.333333, 0.7, 0.901961],
                 "aqua": [0.5, 0.7, 0.901961], "blue": [0.666666, 0.7, 0.901961], "purple": [0.75, 0.7, 0.901961], "magenta": [0.833333, 0.7, 0.901961] }
'''
'''
colourVectors = {"red": [0.0, 0.7, 0.886806], "orange": [0.0, 0.7, 0.901961], "yellow": [0.0, 0.7, 0.901961], "green": [0.0, 0.7, 0.901961],
    "aqua": [0.0, 0.7, 0.901961], "blue": [0.0, 0.7, 0.901961], "purple": [0.0, 0.7, 0.901961], "magenta": [0.0, 0.7, 0.901961] }
'''

# 'no-op' values - 0 degree hue shift and 1x multipliers for saturation and value
colourVectors = {"red": [0.0,1.0,1.0], "orange": [0.0,1.0,1.0], "yellow": [0.0,1.0,1.0], "green": [0.0,1.0,1.0],
    "aqua": [0.0,1.0,1.0], "blue": [0.0,1.0,1.0], "purple": [0.0,1.0,1.0], "magenta": [0.0,1.0,1.0] }


# flag inficating that colour vectors have been modified
coloursChanged = False

# width of a colour band (used for calculating hue changes)
hueWidth = (360.0 / 8.0) / 100.0

'''
    Note that the format of a preset setup is similar the syntax used in the phixer config file (without the UI stuff).
    Syntax is a bit different because it's driven by the Python, not JSON, and we have to deal with position and vector types
    It is essentially the name of the preset with a list of filters to apply, and the parameters to pass to those filters
    For example, a preset might look like:

    { "key": "presetfile.xmp",
    "info": { "name": "Example Preset", "group": "Example Presets" },
    "filters":  [ { "key": "WhiteBalanceFilter", "parameters": [ { "key": "inputTemperature", "val": 0.1, "type": "CIAttributeTypeScalar"},
                                                                   "key": "inputTint", val: 0.0, type: "CIAttributeTypeScalar"} } ]
                  },
                  { "key": "CIVibrance", "parameters":  [ {"key": "inputAmount", "val": 0.4, "type": "CIAttributeTypeScalar"} ] }
                  }
                ]

    Also note that we use an array (rather than a dictionary) for the list of filters so that we can maintain the order of the filters
'''

#----------------------------

def main():

    global infile
    global outfile
    
    # parse the command line args
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="the name of the input XML file")
    parser.add_argument("output", help="the name of the output JSON file")
    args = parser.parse_args()
    
    #print args
    infile = args.input
    outfile = args.output
    
    parseInput(infile)

    # set up an empty preset
    initPreset(outfile)

    # process the input based on the filters we support in the app
    # Note: order is based on Photoshop/Lightroom since those are the main sources of presets
    processInfo()
    processAuto()
    processWhiteBalance()
    processExposure()
    processContrast()
    processToneCurve()
    processClarity()
    processVibrance()
    processSaturation()
    processParametricCurve()
    processHSV()
    processSplitToning()
    processSharpening()
    processCalibration()
    processRGBToneCurves()
    
    processGrain()
    addHSV()
 
    processShadowsHighlights() # do this after colour adjustments

    addToneCurve()

    # process these last
    processGrayscale() # do this last
    processVignette()


    # print the final preset
    #printPreset()

    # and save it...
    savePreset(outfile)


#----------------------------

def parseInput(f):
    # open the XMP file and parse
    with open(f, 'r') as inf:
        strbuffer = inf.read()
    xmp.parse_from_str(strbuffer)
    print("\nProcessing: " + infile + "...")


#----------------------------

def initPreset(f):
    filterMap["key"] = f
    filterMap["info"] ={}
    filterMap["filters"] = []


#----------------------------

def printPreset():
    #print ("Raw map: " + str(filterMap))
    print ("\n\n")
    print ("JSON: " + json.dumps(filterMap, indent=4))


#----------------------------

def savePreset(f):
    with safe_open_w(f) as outf:
        json.dump(filterMap, outf, indent=2)
        print("\nSaved to: " + f + "\n")

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def safe_open_w(path):
    #Open "path" for writing, creating any parent directories as needed.

    mkdir_p(os.path.dirname(path))
    return open(path, 'w')


#----------------------------

def processInfo():
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Name"):
        name = xmp.get_localized_text(XMP_NS_CAMERA_RAW, "Name", "", "us-en")
        #print ("Name: " + str(name))
        filterMap["info"]["name"] = name

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Group"):
        group = xmp.get_localized_text(XMP_NS_CAMERA_RAW, "Group", "", "us-en")
        #print ("Name: " + str(name))
        filterMap["info"]["group"] = group


#----------------------------

def processAuto():
    # if any "Auto" function is specified, then run the auto adjust filter (which adjusts everything)
    auto = False
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "AutoBrightness"):
        auto = True
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "AutoContrast"):
        auto = True
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "AutoExposure"):
        auto = True
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "AutoShadows"):
        auto = True
    if auto:
        filterMap["filters"].append( { 'key':"AutoAdjustFilter", "parameters":[] } )
        print ("...Auto Adjust")


#----------------------------

def processWhiteBalance():
    # keys: either WhiteBalance (preset) and/or Temperature and Tint
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "WhiteBalance"):
        # preset is one of: As Shot, Auto, Daylight, Cloudy, Shade, Tungsten, Fluorescent, Flash, Custom
        # Just ignore As Shot, Auto and Custom
        wbPresets = { "Daylight":    { 'temp': 5500.0, 'tint': 10.0 },
                      "Cloudy":      { 'temp': 6500.0, 'tint': 10.0 },
                      "Shade":       { 'temp': 7500.0, 'tint': 10.0 },
                      "Tungsten":    { 'temp': 2850.0, 'tint': 0.0 },
                      "Fluorescent": { 'temp': 3800.0, 'tint': 21.0 },
                      "Flash":       { 'temp': 5500.0, 'tint': 0.0 } }
                      
        preset = xmp.get_property(XMP_NS_CAMERA_RAW, "WhiteBalance")
        if preset in wbPresets:
            temp = min(wbPresets[preset]['temp'], 10000.0)
            tint = max(min(wbPresets[preset]['tint'], 100.0), -100.0)
            filterMap["filters"].append( { 'key':"WhiteBalanceFilter", "parameters":[ { 'key':"inputTemperature", 'val':temp, 'type':"CIAttributeTypeScalar"},
                                                                                      {'key':"inputTint", 'val': tint, 'type': "CIAttributeTypeScalar"} ]
                                                                 } )
            print ("...Preset White Balance")
        elif preset == "Auto": # for Auto, just run auto correct
            filterMap["filters"].append( { 'key':"AutoAdjustFilter", "parameters":[] } )

        elif preset == "Custom":
            temp = 5500.0
            tint = 0.0
            if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Temperature"):
                temp = min(xmp.get_property_float(XMP_NS_CAMERA_RAW, "Temperature"), 10000.0)

            if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Tint"):
                tint = clamp(xmp.get_property_float(XMP_NS_CAMERA_RAW, "Tint"), -100.0, 100.0)

            filterMap["filters"].append( { 'key':"WhiteBalanceFilter", "parameters":[ { 'key':"inputTemperature", 'val':temp, 'type':"CIAttributeTypeScalar"},
                                                                                 {'key':"inputTint", 'val': tint, 'type': "CIAttributeTypeScalar"} ]
                                    } )
            print ("...Custom White Balance")


#----------------------------

def processExposure():
    # keys: Exposure or Exposure2012. Range -5.0 .. +5.0 -> -10.0 ... +10.0 (but same scale)
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Exposure"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Exposure")
        if abs(value)>0.01:
            filterMap["filters"].append( { 'key':"CIExposureAdjust", "parameters":[{ 'key':"inputEV", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
            print ("...Exposure")
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Exposure2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Exposure2012")
        if abs(value)>0.01:
            filterMap["filters"].append( { 'key':"CIExposureAdjust", "parameters":[{ 'key':"inputEV", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
            print ("...Exposure2012")


#----------------------------

def processContrast():
    
    global toneCurve
    global toneCurveChanged

    minClarity = 1.0
    found = False
    # keys: Contrast or Contrast2012. Range -50..+100 -> 0.25..4.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Contrast"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Contrast")
        if (value<0.0):
            value = 1.0 + value * 0.75 / 50.0
        else:
            value = 1.0 + value * 3.0 / 100.0
        if (value < minClarity):
            print ("WARNING: Contrast too low, setting to: "+str(minClarity))
        value = clamp(value, minClarity, 4.0)
        if abs(value)>0.01:
            filterMap["filters"].append( { 'key':"ContrastFilter", "parameters":[{ 'key':"inputContrast", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
            print ("...Contrast")
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Contrast2012"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Contrast2012")
        if (value<0.0):
            value = 1.0 + value * 0.75 / 50.0
        else:
            value = 1.0 + value * 3.0 / 100.0
        if (value < minClarity):
            print ("WARNING: Contrast too low, setting to: "+str(minClarity))
        value = clamp(value, minClarity, 4.0)
        print ("...Contrast2012")

    if found and abs(value)>0.001:
        # if the value is +ve we can use the built in Contrast Filter
        if value>=0.0:
            value = 1.0 + value * 3.0 / 100.0 # 0..100 -> 1..4
            value = clamp(value, minClarity, 4.0)
            filterMap["filters"].append( { 'key':"ContrastFilter", "parameters":[{ 'key':"inputContrast", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
        else:
            # -ve contrast, the built in filter sucks with this, so adjust the tone curve instead
            shadowVal = toneCurve[1][1] * (1.0 + value/100.0)
            toneCurve[1][1] = clamp (shadowVal, 1.0, 99.0 )
            toneCurveChanged = True

#----------------------------

def processShadowsHighlights():
    # Highlights, Shadows, Whites, Blacks or: Highlights2012, Shadows2012, Whites2012, Blacks2012
    # maybe not the right way to do it, but we will just modify the input values of the tone curve
    # [0]=Blacks [1]=Shadows [2]=??? [3]=Highlights [4]=Whites
    
    global toneCurve
    global toneCurveChanged

    found = False
    
    # look for specific settings of each point and apply them on top of the current curve
    # if the value is (approx) 0 then just ignore it
    
    # not quite sure how this works, e.g what does +100 mean?
    
    b = 0.0
    w = 0.0
    s = 0.0
    h = 0.0
    
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Blacks"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Blacks")
        if abs(value)>0.01:
            found = True
            b = calculateCurveChangeConstrained(toneCurve[0][0], toneCurve[1][0]-10.0, -value, 0.0)
            toneCurve[0][0] = b
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Blacks2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Blacks2012")
        if abs(value)>0.01:
            found = True
            b = calculateCurveChangeConstrained(toneCurve[0][0], -value, toneCurve[1][0]-10.0, 0.0)
            toneCurve[0][0] = b


    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Whites"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Whites")
        if abs(value)>0.01:
            found = True
            w = calculateCurveChangeConstrained(toneCurve[4][0], -value, 100.0, toneCurve[3][0]+10.0)
            toneCurve[4][0] = w
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Whites2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Whites2012")
        if abs(value)>0.01:
            found = True
            w = calculateCurveChangeConstrained(toneCurve[4][0], -value, 100.0, toneCurve[3][0]+10.0)
            toneCurve[4][0] = w

    '''

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Shadows"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Shadows")
        if abs(value)>0.01:
            found = True
            s = calculateCurveChange(toneCurve[1][1], value, 100.0)
            toneCurve[1][1] = s
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Shadows2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Shadows2012")
        if abs(value)>0.01:
            found = True
            s = calculateCurveChange(toneCurve[1][1], value, 100.0)
            toneCurve[1][1] = s

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Highlights"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Highlights")
        if abs(value)>0.01:
            found = True
            h = calculateCurveChange(toneCurve[3][1], value, 100.0)
            toneCurve[3][1] = h
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Highlights2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Highlights2012")
        if abs(value)>0.01:
            found = True
            h = calculateCurveChange(toneCurve[3][1], value, 100.0)
            toneCurve[3][1] = h
    '''

    if found:
        toneCurveChanged = True
        #addToneCurve()
        print("Blacks: " + str(b) + " Shadows:" +str(s) + " Highlights:" + str(h) + " Whites:" + str(w))
        print ("...Blacks/Shadows/Highlights/Whites")


    # try the HighlightShadows filter instead of adjusting the tone curve
    found2 = False
    h = 0.3
    s = 0.0
    sum = 0.0

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Shadows"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Shadows")
        sum = sum + abs(value)
        if abs(value)>0.01:
            found2 = True
            s = clamp (value/100.0, -1.0, 1.0)
            print("Shadows: " + str(value) + " -> " + str(s))
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Shadows2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Shadows2012")
        sum = sum + abs(value)
        if abs(value)>0.01:
            found2 = True
            s = clamp (value/100.0, -1.0, 1.0)
            print("Shadows: " + str(value) + " -> " + str(s))

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Highlights"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Highlights")
        sum = sum + abs(value)
        # only process -ve values (reduce highligts) because that's all the internal filter supports
        #if abs(value)>0.01:
        if value<0.0:
            found2 = True
            h = clamp (-value/100.0, 0.3, 1.0) # check range
            #h = clamp (-value/100.0, 0.0, 1.0) # check range
            print("Highlights: " + str(value) + " -> " + str(h))
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Highlights2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Highlights2012")
        sum = sum + abs(value)
        # only process -ve values (reduce highligts) because that's all the internal filter supports
        #if abs(value)>0.01:
        if value<0.0:
            found2 = True
            h = clamp (-value/100.0, 0.3, 1.0)
            #h = clamp (-value/100.0, 0.0, 1.0)
            print("Highlights: " + str(value) + " -> " + str(h))

    if found2 and abs(sum)>0.01:
        filterMap["filters"].append( { 'key':"CIHighlightShadowAdjust", "parameters":[{ 'key':"inputRadius", 'val': 0.0, 'type': "CIAttributeTypeScalar"},
                                                                                      { 'key':"inputShadowAmount", 'val': s, 'type': "CIAttributeTypeScalar"},
                                                                                      { 'key':"inputHighlightAmount", 'val': h, 'type': "CIAttributeTypeScalar"}
                                                                                      ] } )
        print ("...Shadows/Highlights")


#----------------------------

def processClarity():
    # keys: Clarity or Clarity2012. Range -100.0 .. +100.0 -> -1.0 ... +1.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Clarity"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Clarity") / 100.0
        if abs(value)>0.01:
            filterMap["filters"].append( { 'key':"ClarityFilter", "parameters":[{ 'key':"inputClarity", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
            print ("...Clarity")
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Clarity2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Clarity2012") / 100.0
        if abs(value)>0.01:
            filterMap["filters"].append( { 'key':"ClarityFilter", "parameters":[{ 'key':"inputClarity", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
            print ("...Clarity2012")


#----------------------------

def processVibrance():
    # key: Vibrance. Range -100..+100 -> -1.0..+1.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Vibrance"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Vibrance") / 100.0
        if abs(value)>0.01:
            filterMap["filters"].append( { 'key':"CIVibrance", "parameters":[{ 'key':"inputAmount", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
            print ("...Vibrance")



#----------------------------

def processSaturation():
    # key: Saturation. Range -100..+100 -> 0.0..+2.0 (1.0 is neutral)
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Saturation"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Saturation")
        if abs(value)>0.01:
            value = (value / 100.0) + 1.0
            value = clamp(value, 0.0, 2.0)
            filterMap["filters"].append( { 'key':"SaturationFilter", "parameters":[{ 'key':"inputSaturation", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
            print ("...Saturation")


#----------------------------

def processParametricCurve():
    # this is the Lightroom version of a Tone Curve.
    # keys: ParametricDarks, ParametricLights, ParametricShadows, ParametricHighlights, ParametricShadowSplit, ParametricMidtoneSplit, ParametricHighlightSplit
    # the 'Split' keys affect the tone curve input values, others affect the output values
    # values for output levels are are -100..+100 and represent the change relative to a linear tone curve
    # values for 'Split' variables represent the input value for that transition point (Shadows, Dark etc.). Range 0..100
    # Note: each value is a percentage, i.e. 0..100 (-100..+100 for output adjustments), not an absolute value
    # final conversion is to the range used in the CIToneCurve Filter, which is 0.0..1.0
    # note that I constrained the changes so that they cannot go higher than the next point or lower than the previous point. This is
    # artificial and precludes any 'inversion' type changes (via Parametric values)

    global toneCurve
    global toneCurveChanged
    
    found = False
    sum = 0.0
    

    # look for specific settings of each point and apply them on top of the current curve
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricDarks"):
        #found = True
        #value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricDarks")
        #toneCurve[0][1] = clamp ((toneCurve[0][1] + value), 0.0, 100.0)
        print("WARNING: ignoring ParametricDarks")
    
    
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricShadowSplit"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricShadowSplit")
        toneCurve[1][0] = value
        sum = sum + abs(value)

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricShadows"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricShadows")
        #toneCurve[1][1] = calculateCurveChange(toneCurve[1][1], value, 100.0)
        toneCurve[1][1] = calculateCurveChangeConstrained(toneCurve[1][1], value, toneCurve[2][1]-10.0, toneCurve[0][1]+10.0)
        sum = sum + abs(value)


    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricMidtoneSplit"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricMidtoneSplit")
        toneCurve[2][0] = value
        sum = sum + abs(value)


    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricHighlightSplit"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricHighlightSplit")
        toneCurve[3][0] = value
        sum = sum + abs(value)

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricHighlights"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricHighlights")
        #toneCurve[3][1] = calculateCurveChange(toneCurve[3][1], value, 100.0)
        toneCurve[3][1] = calculateCurveChangeConstrained(toneCurve[3][1], value, toneCurve[4][1]-10.0, toneCurve[2][1]+10.0)
        sum = sum + abs(value)


    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricLights"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricLights")
        toneCurve[4][1] = calculateCurveChange(toneCurve[4][1], value, 100.0)
        sum = sum + abs(value)


    if found and abs(sum)>0.01:
        toneCurveChanged = True
        #addToneCurve()
        print ("...Parametric Curve")


#----------------------------

def processToneCurve():
    # this is the Photoshop version of a Tone Curve. Note, will overwrite any previous Tone Curve or Parametric curve

    global toneCurve
    global toneCurveChanged
    found = False
    

    # first, look for a named preset
    name = ""
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurveName"):
        name = xmp.get_property(XMP_NS_CAMERA_RAW, "ToneCurveName")
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurveName2012"):
        name = xmp.get_property(XMP_NS_CAMERA_RAW, "ToneCurveName2012")
    
    if len(name) > 0:
        found = True
        if name == "Medium Contrast":
            toneCurve = [ [0.0, 0.0], [25.0, 20.0], [50.0, 50.0], [75.0, 80.0], [100.0, 100.0]]
        elif name == "Strong Contrast":
            toneCurve = [ [0.0, 0.0], [25.0, 15.0], [50.0, 50.0], [75.0, 85.0], [100.0, 100.0]]


    # look for tone curve values
    curvename = ""
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurve"):
        curveName = "ToneCurve"
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurvePV2012"):
        curveName = "ToneCurvePV2012"

    if len(name) > 0:
        found = True
        count = xmp.count_array_items(XMP_NS_CAMERA_RAW, curveName)
        if count > 0:
            found = True
            points = []
            for i in range(1, (count+1)):
                item = xmp.get_array_item(XMP_NS_CAMERA_RAW, curveName, i)
                point = map(float, item.split(","))
                points.append(point)
            print("\Input Curve: "+str(points)+"\n")

            # if 2 or less points then ignore (linear anyway), otherwise interpolate
            if (count <2):
                print("ERROR: too few points(" + count + ")")
            #elif (count <= 3):
            else:
                #print("Need to interpolate Tone Curve")
                # split into 2 arrays, convert to 0..100 scale, create spline, interpolate and update the curve
                x, y = zip(*points)
                x2 = [100.0 * f / 255 for f in x]
                y2 = [100.0 * f / 255 for f in y]
                spline = UnivariateSpline(x2, y2, s=0, k=min(5,(count-1)))
                xcurve = [ 0.0, 25.0, 50.0, 75.0, 100.0 ]
                tmp1 = 0.0
                tmp2 = 0.0
                for i in range(0, len(xcurve)):
                    tmp1 = clamp(spline(xcurve[i]), 0.0, 100.0)
                    tmp2 = float(tmp1)
                    if tmp2 < 0.001: # small numbers cause issues with JSON
                        tmp2 = 0.0
                    toneCurve[i] = [xcurve[i], tmp2]

    if found:
        toneCurveChanged = True
        print ("Curve: " + str(toneCurve))
        print ("...Tone Curve")

#----------------------------

def addToneCurve():
    
    global toneCurve
    global toneCurveChanged
    
    if toneCurveChanged:
        filterMap["filters"].append( { 'key':"CIToneCurve",
                                    "parameters":[{ 'key':"inputPoint0", 'val': [(toneCurve[0][0]/100.0), (toneCurve[0][1]/100.0)], 'type': "CIAttributeTypeOffset"},
                                                  { 'key':"inputPoint1", 'val': [(toneCurve[1][0]/100.0), (toneCurve[1][1]/100.0)], 'type': "CIAttributeTypeOffset"},
                                                  { 'key':"inputPoint2", 'val': [(toneCurve[2][0]/100.0), (toneCurve[2][1]/100.0)], 'type': "CIAttributeTypeOffset"},
                                                  { 'key':"inputPoint3", 'val': [(toneCurve[3][0]/100.0), (toneCurve[3][1]/100.0)], 'type': "CIAttributeTypeOffset"},
                                                  { 'key':"inputPoint4", 'val': [(toneCurve[4][0]/100.0), (toneCurve[4][1]/100.0)], 'type': "CIAttributeTypeOffset"} ]
                                    } )

        print ("Curve: " + str(toneCurve))



#----------------------------

def processRGBToneCurves():

    # handles individual RGB Tone Curves

    # Note: do *not* use global tone curve array

    # default tone curves, split into X and Y vectors. Note the 0..1.0 scale
    redX = [ 0.0, 0.25, 0.50, 0.75, 1.00 ]
    redY = [ 0.0, 0.25, 0.50, 0.75, 1.00 ]
    greenX = [ 0.0, 0.25, 0.50, 0.75, 1.00 ]
    greenY = [ 0.0, 0.25, 0.50, 0.75, 1.00 ]
    blueX = [ 0.0, 0.25, 0.50, 0.75, 1.00 ]
    blueY = [ 0.0, 0.25, 0.50, 0.75, 1.00 ]

    found = False
    linearCount = 0
    
    # RED
    curveName = ""
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurvePVRed"):
        curveName = "ToneCurvePVRed"
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurvePV2012Red"):
        curveName = "ToneCurvePV2012Red"
    
    if len(curveName) > 0:
        #found = True
        count = xmp.count_array_items(XMP_NS_CAMERA_RAW, curveName)
        if count > 0:
            found = True
            points = []
            for i in range(1, (count+1)):
                item = xmp.get_array_item(XMP_NS_CAMERA_RAW, curveName, i)
                point = map(float, item.split(","))
                points.append(point)
            print("\nInput Red Curve: "+str(points)+"\n")
            
            # if we have exactly 5 points then we can use them directly, otherwise we need to interpolate to get those 5 points
            if (count == 5):
                x, y = zip(*points)
                redY = [f / 255 for f in y]

            elif (count <= 2):
                print("WARN: too few points(" + str(count) + "). Using Linear Curve")
                linearCount += 1
            #elif (count <= 3):
            else:
                #print("Need to interpolate Tone Curve")
                # split into 2 arrays, convert to 0..1.0 scale, create spline, interpolate and update the curve
                x, y = zip(*points)
                x2 = [f / 255 for f in x]
                y2 = [f / 255 for f in y]
                spline = UnivariateSpline(x2, y2, s=0, k=min(5,(count-1)))
                tmp = 0.0
                for i in range(0, len(redX)):
                    tmp = clamp(spline(redX[i]), 0.0, 1.0)
                    redY[i] = float(tmp)
                    if redY[i] < 0.001: # small numbers case issues with JSON
                        redY[i] = 0.0


    # GREEN
    curveName = ""
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurvePVGreen"):
        curveName = "ToneCurvePVGreen"
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurvePV2012Green"):
        curveName = "ToneCurvePV2012Green"
    
    if len(curveName) > 0:
        #found = True
        count = xmp.count_array_items(XMP_NS_CAMERA_RAW, curveName)
        if count > 0:
            found = True
            points = []
            for i in range(1, (count+1)):
                item = xmp.get_array_item(XMP_NS_CAMERA_RAW, curveName, i)
                point = map(float, item.split(","))
                points.append(point)
            print("\nInput Green Curve: "+str(points)+"\n")
            
            # if we have exactly 5 points then we can use them directly, otherwise we need to interpolate to get those 5 points
            if (count == 5):
                x, y = zip(*points)
                greenY = [f / 255 for f in y]

            elif (count <= 2):
                print("WARN: too few points(" + str(count) + "). Using Linear Curve")
                linearCount += 1
            #elif (count <= 3):
            else:
                #print("Need to interpolate Tone Curve")
                # split into 2 arrays, convert to 0..1.0 scale, create spline, interpolate and update the curve
                x, y = zip(*points)
                x2 = [f / 255 for f in x]
                y2 = [f / 255 for f in y]
                spline = UnivariateSpline(x2, y2, s=0, k=min(5,(count-1)))
                tmp = 0.0
                for i in range(0, len(greenX)):
                    tmp = clamp(spline(greenX[i]), 0.0, 1.0)
                    greenY[i] = float(tmp)
                    if greenY[i] < 0.001: # small numbers case issues with JSON
                        greenY[i] = 0.0


    # BLUE
    curveName = ""
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurvePVBlue"):
        curveName = "ToneCurvePVBlue"
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ToneCurvePV2012Blue"):
        curveName = "ToneCurvePV2012Blue"
    
    if len(curveName) > 0:
        #found = True
        count = xmp.count_array_items(XMP_NS_CAMERA_RAW, curveName)
        if count > 0:
            found = True
            points = []
            for i in range(1, (count+1)):
                item = xmp.get_array_item(XMP_NS_CAMERA_RAW, curveName, i)
                point = map(float, item.split(","))
                points.append(point)
            print("\nInput Blue Curve: "+str(points)+"\n")
            
            # if we have exactly 5 points then we can use them directly, otherwise we need to interpolate to get those 5 points
            if (count == 5):
                x, y = zip(*points)
                blueY = [f / 255 for f in y]

            elif (count <= 2):
                print("WARN: too few points(" + str(count) + "). Using Linear Curve")
                linearCount += 1
            #elif (count <= 3):
            else:
                #print("Need to interpolate Tone Curve")
                # split into 2 arrays, convert to 0..1.0 scale, create spline, interpolate and update the curve
                x, y = zip(*points)
                x2 = [f / 255 for f in x]
                y2 = [f / 255 for f in y]
                spline = UnivariateSpline(x2, y2, s=0, k=min(5,(count-1)))
                tmp = 0.0
                for i in range(0, len(blueX)):
                    tmp = clamp(spline(blueX[i]), 0.0, 1.0)
                    blueY[i] = float(tmp)
                    if blueY[i] < 0.001: # small numbers case issues with JSON
                        blueY[i] = 0.0



    if linearCount == 3:
        found = False
        print("WARNING: ignoring RGB Tone Curve")

    if found:
        print("\nOutput Red Curve:\n    X:"+str(redX)+"\n    Y:"+str(redY))
        print("\nOutput Green Curve:\n    X:"+str(greenX)+"\n    Y:"+str(greenY))
        print("\nOutput Blue Curve:\n    X:"+str(blueX)+"\n    Y:"+str(blueY)+"\n")
        filterMap["filters"].append( { 'key':"RGBChannelToneCurve",
                                    "parameters":[{ 'key':"inputRedXvalues",   'val': redX, 'type': "CIAttributeTypeVector"},
                                                  { 'key':"inputRedYvalues",   'val': redY, 'type': "CIAttributeTypeVector"},
                                                  { 'key':"inputGreenXvalues", 'val': greenX, 'type': "CIAttributeTypeVector"},
                                                  { 'key':"inputGreenYvalues", 'val': greenY, 'type': "CIAttributeTypeVector"},
                                                  { 'key':"inputBlueXvalues",  'val': blueX, 'type': "CIAttributeTypeVector"},
                                                  { 'key':"inputBlueYvalues",  'val': blueY, 'type': "CIAttributeTypeVector"} ]
                                    } )
        print ("...RGB Tone Curves")

#----------------------------

def processHSV():
    
    global colourVectors
    global coloursChanged
    
    '''
        vector is [hue, saturation, brightness]
        range of input is -100..+100
        range of output is 0.0..+1.0
        attribute type CIAttributeTypePosition3 (CIVector)
        '''
    
    # update colour vectors
    found = False
    sum = 0.0 # check to see if anything changed
    for key in colourVectors.keys():
        h = 0.0
        s = 0.0
        v = 0.0
        tag = key.capitalize()
        if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "HueAdjustment"+tag):
            found = True
            h = xmp.get_property_float(XMP_NS_CAMERA_RAW, "HueAdjustment"+tag)

            sum = sum + abs(h)
            if abs(h)>0.01:
                #value = colourVectors[key][0] * (1.0 + h / 100.0)
                #value = (h / 100.0) * hueWidth
                value = (h / 100.0) / 8.0 # treat as a %age of the colour band
                #value = 1.0 + value
                colourVectors[key][0] = colourVectors[key][0] + value
        if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SaturationAdjustment"+tag):
            found = True
            s = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SaturationAdjustment"+tag)
            if abs(s)>0.01:
                value = (s / 100.0) # treat as a %age change
                colourVectors[key][1] = colourVectors[key][1] + value
                #colourVectors[key][1] = calculateCurveChange(colourVectors[key][1], value, 1.0)
            sum = sum + abs(s)
        if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "LuminanceAdjustment"+tag):
            found = True
            v = xmp.get_property_float(XMP_NS_CAMERA_RAW, "LuminanceAdjustment"+tag)
            if abs(v)>0.01:
                value = (v / 100.0) # treat as a %age change
                colourVectors[key][1] = colourVectors[key][1] + value
            #colourVectors[key][2] = calculateCurveChange(colourVectors[key][2], value, 1.0)
            sum = sum + abs(v)
        
        # if hue, saturation and value are all 0 then set to noop values [0, 1, 1]
        if (abs(h) + abs(s) + abs(v)) < 0.01:
            colourVectors[key] = [0.0, 1.0, 1.0]

        print (str(tag) + ": h:" + str(h) + ": s:" + str(s) + ": v:" + str(v))

    if found:
        if (sum > 0.01): # check that something was specified, not all 0s
            coloursChanged = True
            print ("...HSV")
            print ("Colours: " + str(colourVectors) + "\n")
        else:
            print ("Ignoring HSV")



#----------------------------

def processCalibration():
    # This is an 'older' way to change hue and saturation. Range is -100..+100 and represents % change
    
    
    global colourVectors
    global coloursChanged
    
    found = False
    
    # update colour vectors
    found = False
    sum = 0.0 # check to see if anything changed
    h = 0.0
    s = 1.0
    v = 1.0

    for key in ["red", "green", "blue"]:
        tag = key.capitalize()
        if xmp.does_property_exist(XMP_NS_CAMERA_RAW, tag+"Hue"):
            found = True
            h = xmp.get_property_float(XMP_NS_CAMERA_RAW, tag+"Hue")
            sum = sum + abs(h)
            if abs(h)>0.01:
                print(tag+" Hue: "+str(h))
                # if noop values in use([0, 1, 1]), then replace with reference colour
                #if (approxEqual(colourVectors[key][0],0.0) and approxEqual(colourVectors[key][1],1.0) and approxEqual(colourVectors[key][2],1.0)):
                #    colourVectors[key] = refColour[key]
                #value = (h / 100.0) * hueWidth # treat as a %age of the hue band (not the entire hue range)
                value = (h / 100.0)  / 8.0 # treat as a %age of the colour band
                #value = colourVectors[key][0] + value
                colourVectors[key][0] = colourVectors[key][0] + value
        if xmp.does_property_exist(XMP_NS_CAMERA_RAW, tag+"Saturation"):
            found = True
            s = xmp.get_property_float(XMP_NS_CAMERA_RAW, tag+"Saturation")
            sum = sum + abs(s)
            if abs(s)>0.01:
                print(tag+" Sat: "+str(s))
                # if noop values in use([0, 1, 1]), then replace with reference colour
                #if (approxEqual(colourVectors[key][0],0.0) and approxEqual(colourVectors[key][1],1.0) and approxEqual(colourVectors[key][2],1.0)):
                #    colourVectors[key] = refColour[key]
                value = s / 100.0
                colourVectors[key][1] = colourVectors[key][1] + value
                #colourVectors[key][1] = calculateCurveChange(colourVectors[key][1], value, 1.0)

    if found and (sum > 0.01):
        coloursChanged = True
        print ("Colours: " + str(colourVectors) + "\n")
        print ("...Calibration")


#----------------------------

def addHSV():
    if coloursChanged:
        filterMap["filters"].append( { 'key':"MultiBandHSV", "parameters":[{ 'key':"inputRedShift", 'val': colourVectors["red"], 'type': "CIAttributeTypePosition3"},
                                                                           { 'key':"inputOrangeShift", 'val': colourVectors["orange"], 'type': "CIAttributeTypePosition3"},
                                                                           { 'key':"inputYellowShift", 'val': colourVectors["yellow"], 'type': "CIAttributeTypePosition3"},
                                                                           { 'key':"inputGreenShift", 'val': colourVectors["green"], 'type': "CIAttributeTypePosition3"},
                                                                           { 'key':"inputAquaShift", 'val': colourVectors["aqua"], 'type': "CIAttributeTypePosition3"},
                                                                           { 'key':"inputBlueShift", 'val': colourVectors["blue"], 'type': "CIAttributeTypePosition3"},
                                                                           { 'key':"inputPurpleShift", 'val': colourVectors["purple"], 'type': "CIAttributeTypePosition3"},
                                                                           { 'key':"inputMagentaShift", 'val': colourVectors["magenta"], 'type': "CIAttributeTypePosition3"} ]
                                    } )
        print ("Colours: " + str(colourVectors) + "\n")

#----------------------------

def processSplitToning():

    found = False
    highlightHue = 0.0
    highlightSaturation = 0.5
    shadowHue = 0.1
    shadowSaturation = 0.5
    sum = 0.0

    # straightforward conversion here, just convert range 0..100 to 0.0..1.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SplitToningHighlightHue"):
        found = True
        highlightHue = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SplitToningHighlightHue") / 360.0
        sum = sum + abs(highlightHue)

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SplitToningHighlightSaturation"):
        found = True
        highlightSaturation = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SplitToningHighlightSaturation") / 100.0
        sum = sum + abs(highlightSaturation)

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SplitToningShadowHue"):
        found = True
        shadowHue = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SplitToningShadowHue") / 360.0
        sum = sum + abs(shadowHue)

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SplitToningShadowSaturation"):
        found = True
        shadowSaturation = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SplitToningShadowSaturation") / 100.0
        sum = sum + abs(shadowSaturation)

    if found and abs(sum)>0.01:
        filterMap["filters"].append( { 'key':"SplitToningFilter", "parameters":[{ 'key':"inputHighlightHue", 'val': highlightHue, 'type': "CIAttributeTypeScalar"},
                                                                                { 'key':"inputHighlightSaturation", 'val': highlightSaturation, 'type': "CIAttributeTypeScalar"},
                                                                                { 'key':"inputShadowHue", 'val': shadowHue, 'type': "CIAttributeTypeScalar"},
                                                                                { 'key':"inputShadowSaturation", 'val': shadowSaturation, 'type': "CIAttributeTypeScalar"} ]
                                    } )
        print ("...Split Toning")

#----------------------------

def processSharpening():
    # there are 2 kinds of sharpening: 'general' sharpening by an amount, and unsharp mask

    # general sharpening, use Luminosity Sharpening
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Sharpness"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Sharpness") / 50.0
        value = clamp(value, 0.0, 2.0)
        if abs(value)>0.01:
            filterMap["filters"].append( { 'key':"CISharpenLuminance", "parameters":[{ 'key':"inputSharpness", 'val': value, 'type': "CIAttributeTypeScalar"} ] } )
            print ("...Sharpening")

    # unsharp mask
    found = False
    amount = 0.85
    radius = 1.0
    threshold = 0.4

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SharpenDetail"):
        found = True
        amount = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SharpenDetail") / 100.0

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SharpenRadius"):
        found = True
        radius = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SharpenRadius")

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SharpenThreshold"):
        found = True
        threshold = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SharpenThreshold")

    if found and approxEqual(amount, 0.0):
        filterMap["filters"].append( { 'key':"UnsharpMaskFilter", "parameters":[{ 'key':"inputAmount", 'val': amount, 'type': "CIAttributeTypeScalar"},
                                                                                { 'key':"inputRadius", 'val': radius, 'type': "CIAttributeTypeScalar"},
                                                                                { 'key':"inputThreshold", 'val': threshold, 'type': "CIAttributeTypeScalar"} ]
                                    } )
        print ("...Unsharp Mask")

#----------------------------

def processVignette():
    # old: Midpoint, Radius, VignetteAmount, VignetteMidpoint
    # new: PostCropVignetteAmount, PostCropVignetteFeather, PostCropVignetteMidpoint, PostCropVignetteRoundness, PostCropVignetteStyle

    # default values
    radius = 0.0
    intensity = 0.5
    center = [0.0, 0.0]
    falloff = 0.5
    found1 = False
    found2 = False

    # Newest form. Amount must be non-zero to proceed
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "PostCropVignetteAmount"):
        found1 = True
        intensity = -xmp.get_property_float(XMP_NS_CAMERA_RAW, "PostCropVignetteAmount") / 100.0  # flip polarity
        if abs(intensity) < 0.01:
            found1 = False
        else:
            #if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "PostCropVignetteMidpoint"):
            #    falloff = xmp.get_property_float(XMP_NS_CAMERA_RAW, "PostCropVignetteMidpoint") * 10.0 # % to pixels, so unkown transform, guess at 10x
            if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "PostCropVignetteFeather"):
                falloff = xmp.get_property_float(XMP_NS_CAMERA_RAW, "PostCropVignetteFeather") / 100.0
            # leave center as [0,0], which will then default to the center of the image

    # older form:
    if (not found1) and xmp.does_property_exist(XMP_NS_CAMERA_RAW, "VignetteAmount"):
        found2 = True
        intensity = -xmp.get_property_float(XMP_NS_CAMERA_RAW, "VignetteAmount") / 100.0  # flip polarity
        if abs(intensity) < 0.01:
            found2 = False
        #else:
        #if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "VignetteMidpoint"):
        #falloff = xmp.get_property_float(XMP_NS_CAMERA_RAW, "VignetteMidpoint") * 10.0 # % to pixels, so unkown transform, guess at 10x


    if found1 or found2:
        filterMap["filters"].append( { 'key':"CIVignetteEffect", "parameters":[{ 'key':"inputCenter", "val": center, "type": "CIAttributeTypePosition" },
                                                                               { 'key':"inputRadius", "val": radius, "type": "CIAttributeTypeDistance"},
                                                                               { 'key':"inputIntensity", "val": intensity, "type": "CIAttributeTypeScalar"},
                                                                               { 'key':"inputFalloff", "val": falloff, "type": "CIAttributeTypeScalar"} ]
                                    } )
        print ("...Vignette")


#----------------------------

def processGrayscale():
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ConvertToGrayscale"):
        flag = xmp.get_property_bool(XMP_NS_CAMERA_RAW, "ConvertToGrayscale")
        if flag:
            filterMap["filters"].append( { 'key':"CIPhotoEffectMono", "parameters":[] } )
            print ("...ConvertToGrayscale")



#----------------------------

def processGrain():
    '''
        GrainAmount 0..100 -> 0.0..1.0
        GrainSize 0..100 -> 0.0..1.0
        GrainFrequency 0..100 (not used)
    '''
    found = False
    size = 0.0
    
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "GrainAmount"):
        found = True
        amount = xmp.get_property_float(XMP_NS_CAMERA_RAW, "GrainAmount") / 100.0
    
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "GrainSize"):
        found = True
        size = xmp.get_property_float(XMP_NS_CAMERA_RAW, "GrainSize") / 100.0
    

    if found and not approxEqual(amount, 0.0):
        filterMap["filters"].append( { 'key':"GrainFilter", "parameters":[{ 'key':"inputAmount", 'val': amount, 'type': "CIAttributeTypeScalar"},
                                                                          { 'key':"inputSize", 'val': size, 'type': "CIAttributeTypeScalar"} ]
                                    } )
        print ("...Film Grain")

#----------------------------
# calculates the change to a "curve". We assume the change is a percentage of the remaining distance above/below the curve
# change is -100..+100 and emulates Photoshop/Lightroom controls
# scale is the maximum value of the curve (typically 1.0 or 100.0 here)
def calculateCurveChange(currval, change, scale):
    value = currval
    if change>0.0:
        value = currval + (scale - currval) * change / 100.0 # %age of remaining 'room'
    else:
        value = currval + (scale * change / 100.0)
    
    return clamp(value, 0.0, scale)

# same thing but between two bounds
def calculateCurveChangeConstrained(currval, change, upper, lower):
    value = currval
    if change>0.0:
        value = currval + (upper - currval) * change / 100.0 # %age of remaining 'room'
    else:
        value = currval + (currval - lower) * change / 100.0

    value = clamp(value, lower, upper)
    print ("Change: "+str(change) + str(currval) + " -> " + str(value))
    return value


#----------------------------

# utility function to clamp a value between the suppied min and max values
def clamp(value, minv, maxv):
    return max(min(value, maxv), minv)

#----------------------------

# utility function to check if a (float) var is approximately equal to the supplied number
def approxEqual(var, value):
    if abs(var - value) < 0.001:
        return True
    else:
        return False

#----------------------------


# execute main function
main()
