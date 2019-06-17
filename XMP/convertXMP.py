#! /usr/bin/python

# Script to convert a Photoshop/Lightroom XMP preset into the equivalent JSON data for use with phixer.

# NOTE: reference: http://www.exiv2.org/tags-xmp-crs.html for a list of keys
#                  https://www.spacetelescope.org/static/projects/python-xmp-toolkit/docs/reference.html for XMPMeta APIs

# Also note that the preset keys changed in 2012 so sometimes you have to check for both the old (they have "2012" in the name) and the new

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

'''
    Note that the format of a preset setup is similar the syntax used in the phixer config file (without the UI stuff).
    Syntax is a bit different because it's driven by the Python syntax, not JSON, and we have to deal with position and vector types
    It is essentially the name of the preset with a list of filters to apply, and the parameters to pass to those filters
    For example, a preset might look like:

    { "key": "presetfile.xmp",
    "info": { "name": "Example Preset", "group": "Example Presets" },
    "filters":  [ { "WhiteBalanceFilter": { "inputTemperature": { val: 0.1, type: "CIAttributeTypeScalar"},
                                            "inputTint": { val: 0.0, type: "CIAttributeTypeScalar"} }
                  },
                  { "CIVibrance":  {"inputAmount": {"val": 0.4, "type": "CIAttributeTypeScalar"} }
                  }
                ]

    Also note that we use an array (rather than a dictionary) for the list of filters so that we can maintain the order of the filters
'''

# there are several ways to change the tone curve, so make it global and have each method build on any previous changes
# default is a linear tomne curve:
toneCurve = [ [0.0, 0.0], [25.0, 25.0], [50.0, 50.0], [75.0, 75.0], [100.0, 100.0]]

#----------------------------

def main():

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
    processShadowsHighlights()
    processClarity()
    processVibrance()
    processSaturation()
    processParametricCurve()
    processToneCurve()
    processHSV()
    processSplitToning()
    processSharpening()
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
    print ("JSON: " + json.dumps(filterMap))


#----------------------------

def savePreset(f):
    with safe_open_w(f) as outf:
        json.dump(filterMap, outf)
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
        filterMap["filters"].append( {"AutoAdjustFilter":{} } )
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
            filterMap["filters"].append( {"WhiteBalanceFilter": { "inputTemperature": { 'val':temp, 'type':"CIAttributeTypeScalar"},
                                                                  "inputTint": { 'val': tint, 'type': "CIAttributeTypeScalar"}
                                                                } } )
        elif preset == "Auto": # for Auto, just run auto correct
            filterMap["filters"].append( {"AutoAdjustFilter":{} } )

    # look for Temperature and/or Tint settings (can be applied on top of preset)
    
    # build dictionary of parameters
    argDict = {}
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Temperature"):
        # keys: Temperature. Range 2000..50000 -> 2000..10000
        value = min(xmp.get_property_float(XMP_NS_CAMERA_RAW, "Temperature"), 10000.0)
        argDict["inputTemperature"] = { 'val': value, 'type': "CIAttributeTypeScalar"}

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Tint"):
        # keys: Tint. Range -150..+150 -> -100..+100
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Tint")
        #value = max(min(value, 100.0), -100.0)
        value = clamp(value, -100.0, 100.0)
        argDict["inputTint"] = { 'val': value, 'type': "CIAttributeTypeScalar"}

    # if args were found then add them to the filter map
    if bool(argDict):
        filterMap["filters"].append( {"WhiteBalanceFilter": argDict} )
        print ("...White Balance")


#----------------------------

def processExposure():
    # keys: Exposure or Exposure2012. Range -4.0 .. +4.0 -> -10.0 ... +10.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Exposure"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Exposure") * 10.0 / 4.0
        filterMap["filters"].append( {"CIExposureAdjust": { "inputEV": { 'val': value, 'type': "CIAttributeTypeScalar"} } } )
        print ("...Exposure")
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Exposure2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Exposure2012") * 10.0 / 4.0
        filterMap["filters"].append( {"CIExposureAdjust": { "inputEV": { 'val': value, 'type': "CIAttributeTypeScalar"} } } )
        print ("...Exposure2012")


#----------------------------

def processContrast():
    # keys: Contrast or Contrast2012. Range -50..+100 -> -0.25..4.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Contrast"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Contrast")
        value = ((value+50)/150) * 4.25 - 0.25
        filterMap["filters"].append( {"ContrastFilter": { "inputContrast": { 'val': value, 'type': "CIAttributeTypeScalar"} } } )
        print ("...Contrast")
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Contrast2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Contrast2012")
        value = ((value+50)/150) * 4.25 - 0.25
        filterMap["filters"].append( {"ContrastFilter": { "inputContrast": { 'val': value, 'type': "CIAttributeTypeScalar"} } } )
        print ("...Contrast2012")


#----------------------------

def processShadowsHighlights():
    # Highlights, Shadows, Whites, Blacks or: Highlights2012, Shadows2012, Whites2012, Blacks2012
    # maybe not the right way to do it, but we will just modify the input values of the tone curve
    # [0]=Blacks [1]=Shadows [2]=??? [3]=Highlights [4]=Whites
    found = False
    
    # look for specific settings of each point and apply them on top of the current curve
    # if the value is (approx) 0 then just ignore it
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Blacks"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Blacks")
        if abs(value)<0.01:
            found = False
        else:
            toneCurve[0][0] = clamp ((toneCurve[0][0] - value), 0.0, toneCurve[1][0])
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Blacks2012"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Blacks2012")
        if abs(value)<0.01:
            found = False
        else:
            toneCurve[0][0] = clamp ((toneCurve[0][0] - value), 0.0, toneCurve[1][0])

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Shadows"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Shadows")
        if abs(value)<0.01:
            found = False
        else:
            toneCurve[1][0] = clamp ((toneCurve[0][0] - value), toneCurve[0][0], toneCurve[2][0])
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Shadows2012"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Shadows2012")
        if abs(value)<0.01:
            found = False
        else:
            toneCurve[1][0] = clamp ((toneCurve[0][0] - value), toneCurve[0][0], toneCurve[2][0])

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Highlights"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Highlights")
        if abs(value)<0.01:
            found = False
        else:
            toneCurve[3][0] = clamp ((toneCurve[3][0] - value), toneCurve[2][0], toneCurve[4][0])
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Highlights2012"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Highlights2012")
        if abs(value)<0.01:
            found = False
        else:
            toneCurve[3][0] = clamp ((toneCurve[3][0] - value), toneCurve[2][0], toneCurve[4][0])

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Whites"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Whites")
        if abs(value)<0.01:
            found = False
        else:
            toneCurve[5][0] = clamp ((toneCurve[5][0] - value), toneCurve[4][0], 100.0)
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Whites2012"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Whites2012")
        if abs(value)<0.01:
            found = False
        else:
            toneCurve[5][0] = clamp ((toneCurve[5][0] - value), toneCurve[4][0], 100.0)

    if found:
        addToneCurve()
        print ("...Shadows/Highlights")

#----------------------------

def processClarity():
    # keys: Clarity or Clarity2012. Range -100.0 .. +100.0 -> -1.0 ... +1.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Clarity"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Clarity") / 100.0
        filterMap["filters"].append( {"ClarityFilter": { "inputClarity": { 'val': value, 'type': "CIAttributeTypeScalar"} } } )
        print ("...Clarity")
    elif xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Clarity2012"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Clarity2012") / 100.0
        filterMap["filters"].append( {"ClarityFilter": { "inputClarity": { 'val': value, 'type': "CIAttributeTypeScalar"} } } )
        print ("...Clarity2012")


#----------------------------

def processVibrance():
    # key: Vibrance. Range -100..+100 -> -1.0..+1.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Vibrance"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Vibrance") / 100.0
        filterMap["filters"].append( {"CIVibrance": { "inputAmount": { 'val': value, 'type': "CIAttributeTypeScalar"} } } )
        print ("...Vibrance")



#----------------------------

def processSaturation():
    # key: Saturation. Range -100..+100 -> -1.0..+1.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Saturation"):
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Saturation") / 100.0
        filterMap["filters"].append( {"SaturationFilter": { "inputSaturation": {'val': value, 'type': "CIAttributeTypeScalar"} } } )
        print ("...Saturation")


#----------------------------

def processParametricCurve():
    # this is the Lightroom version of a Tone Curve. Note, will be overwritten by a subsequent Tone Curve, if present
    # keys: ParametricDarks, ParametricLights, ParametricShadows, ParametricHighlights, ParametricShadowSplit, ParametricMidtoneSplit, ParametricHighlightSplit
    # the 'Split' keys affect the tone curve input values, others affect the output values
    # values for output levels are are -100..+100 and represent the change relative to a linear tone curve
    # values for 'Split' variables represent the input value for that transition point (Shadows, Dark etc.). Range 0..100
    # Note: each value is a percentage, i.e. 0..100 (-100..+100 for output adjustments), not an absoulte value
    # final conversion is to the range used in the CIToneCurve Filter, which is 0.0..1.0

    global toneCurve

    found = False
    

    # look for specific settings of each point and apply them on top of the current curve
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricShadows"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricShadows")
        toneCurve[0][1] = clamp ((toneCurve[0][1] + value), 0.0, 100.0)

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricShadowSplit"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricShadowSplit")
        toneCurve[1][0] = value

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricDarks"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricDarks")
        toneCurve[1][1] = clamp ((toneCurve[1][1] + value), 0.0, 100.0)
    
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricMidtoneSplit"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricMidtoneSplit")
        toneCurve[2][0] = value

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricLights"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricLights")
        toneCurve[3][1] = clamp ((toneCurve[3][1] + value), 0.0, 100.0)

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricHighlightSplit"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricHighlightSplit")
        toneCurve[3][0] = value
    
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "ParametricHighlights"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "ParametricHighlights")
        toneCurve[4][1] = clamp ((toneCurve[4][1] + value), 0.0, 100.0)
    

    if found:
        addToneCurve()
        print ("...Parametric Curve")


#----------------------------

def processToneCurve():
    # this is the Photoshop version of a Tone Curve. Note, will overwrite any previous Tone Curve or Parametric curve

    global toneCurve
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
            #print("\nPoints: "+str(points)+"\n")

            # if we have exactly 5 points then we can use them directly, otherwise we need to interpolate to get those 5 points
            if count == 5:
                toneCurve = points
            else:
                #print("Need to interpolate Tone Curve")
                # split into 2 arrays, convert to 0..100 scale, create spline, interpolate and update the curve
                x, y = zip(*points)
                x2 = [100.0 * f / 255 for f in x]
                y2 = [100.0 * f / 255 for f in y]
                spline = UnivariateSpline(x2, y2, s=0)
                xcurve = [0.0, 25.0, 50.0, 75.0, 100.0]
                for i in range(0, len(xcurve)):
                    toneCurve[i] = [xcurve[i], clamp(spline(xcurve[i]), 0.0, 100.0)]

    if found:
        addToneCurve()
        print ("...Tone Curve")

#----------------------------

def addToneCurve():
    
    global toneCurve

    filterMap["filters"].append( {"CIToneCurve": { "inputPoint0": {'val': [(toneCurve[0][0]/100.0), (toneCurve[0][1]/100.0)], 'type': "CIAttributeTypeOffset"},
                                                   "inputPoint1": {'val': [(toneCurve[1][0]/100.0), (toneCurve[1][1]/100.0)], 'type': "CIAttributeTypeOffset"},
                                                   "inputPoint2": {'val': [(toneCurve[2][0]/100.0), (toneCurve[2][1]/100.0)], 'type': "CIAttributeTypeOffset"},
                                                   "inputPoint3": {'val': [(toneCurve[3][0]/100.0), (toneCurve[3][1]/100.0)], 'type': "CIAttributeTypeOffset"},
                                                   "inputPoint4": {'val': [(toneCurve[4][0]/100.0), (toneCurve[4][1]/100.0)], 'type': "CIAttributeTypeOffset"} }
                                  } )

    # print ("Curve: " + str(curve))

#----------------------------

def processHSV():
    '''
        vector is [hue, saturation, brightness]
        range of input is -100..+100
        range of output is 0.0..+1.0
        attribute type CIAttributeTypePosition3 (CIVector)
        '''
    # set up default vectors
    colourVectors = {"red": [0.0,1.0,1.0], "orange": [0.0,1.0,1.0], "yellow": [0.0,1.0,1.0], "green": [0.0,1.0,1.0],
                     "aqua": [0.0,1.0,1.0], "blue": [0.0,1.0,1.0], "purple": [0.0,1.0,1.0], "magenta": [0.0,1.0,1.0] }
    
    # update colour vectors
    found = False
    for key in colourVectors.keys():
        tag = key.capitalize()
        if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "HueAdjustment"+tag):
            found = True
            # Hue is a little different in that 0 represents no shift and the value 'wraps' rather than clamps
            value = colourVectors[key][0] + (xmp.get_property_float(XMP_NS_CAMERA_RAW, "HueAdjustment"+tag) / 100.0)
            if value < 0.0:
                value = 1.0 + value
            colourVectors[key][0] = value
        if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SaturationAdjustment"+tag):
            found = True
            value = colourVectors[key][1] + (xmp.get_property_float(XMP_NS_CAMERA_RAW, "SaturationAdjustment"+tag) / 100.0)
            colourVectors[key][1] = value
        if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "LuminanceAdjustment"+tag):
            found = True
            value = colourVectors[key][2] + (xmp.get_property_float(XMP_NS_CAMERA_RAW, "LuminanceAdjustment"+tag) / 100.0)
            colourVectors[key][2] = value

    if found:
        filterMap["filters"].append( {"MultiBandHSV": { "inputRedShift":     {'val': colourVectors["red"], 'type': "CIAttributeTypePosition3"},
                                                                "inputOrangeShift":  {'val': colourVectors["orange"], 'type': "CIAttributeTypePosition3"},
                                                                "inputYellowShift":  {'val': colourVectors["yellow"], 'type': "CIAttributeTypePosition3"},
                                                                "inputGreenShift":   {'val': colourVectors["green"], 'type': "CIAttributeTypePosition3"},
                                                                "inputAquaShift":    {'val': colourVectors["aqua"], 'type': "CIAttributeTypePosition3"},
                                                                "inputBlueShift":    {'val': colourVectors["blue"], 'type': "CIAttributeTypePosition3"},
                                                                "inputPurpleShift":  {'val': colourVectors["purple"], 'type': "CIAttributeTypePosition3"},
                                                                "inputMagentaShift": {'val': colourVectors["magenta"], 'type': "CIAttributeTypePosition3"} }
                                              } )

        print ("...HSV")
        #print ("\nvectors: " + str(colourVectors) + "\n")

#----------------------------

def processSplitToning():

    found = False
    highlightHue = 0.0
    highlightSaturation = 0.5
    shadowHue = 0.1
    shadowSaturation = 0.5

    # straightforward conversion here, just convert range 0..100 to 0.0..1.0
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SplitToningHighlightHue"):
        found = True
        highlightHue = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SplitToningHighlightHue") / 100.0

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SplitToningHighlightSaturation"):
        found = True
        highlightSaturation = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SplitToningHighlightSaturation") / 100.0

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SplitToningShadowHue"):
        found = True
        shadowHue = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SplitToningShadowHue") / 100.0

    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "SplitToningShadowSaturation"):
        found = True
        shadowSaturation = xmp.get_property_float(XMP_NS_CAMERA_RAW, "SplitToningShadowSaturation") / 100.0
    
    if found:
        filterMap["filters"].append( {"SplitToningFilter": { "inputHighlightHue":         {'val': highlightHue, 'type': "CIAttributeTypeScalar"},
                                                             "inputHighlightSaturation":  {'val': highlightSaturation, 'type': "CIAttributeTypeScalar"},
                                                             "inputShadowHue":            {'val': shadowHue, 'type': "CIAttributeTypeScalar"},
                                                             "inputShadowSaturation":     {'val': shadowSaturation, 'type': "CIAttributeTypeScalar"} }
                                    } )
        print ("...Split Toning")

#----------------------------

def processSharpening():
    # there are 2 kinds of sharpening: 'general' sharpening by an amount, and unsharp mask

    # general sharpening, use Luminosity Sharpening
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "Sharpness"):
        found = True
        value = xmp.get_property_float(XMP_NS_CAMERA_RAW, "Sharpness")
        filterMap["filters"].append( {"CISharpenLuminance": { "inputSharpness": { 'val': value, 'type': "CIAttributeTypeScalar"} } } )
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

    if found:
        filterMap["filters"].append( {"UnsharpMaskFilter": { "inputAmount": {'val': amount, 'type': "CIAttributeTypeOffset"},
                                                             "inputRadius": {'val': radius, 'type': "CIAttributeTypeOffset"},
                                                             "inputThreshold": {'val': threshold, 'type': "CIAttributeTypeOffset"} }
                                     } )
        print ("...Unsharp Mask")

#----------------------------

def processVignette():
    # old: Midpoint, Radius, VignetteAmount, VignetteMidpoint
    # new: PostCropVignetteAmount, PostCropVignetteFeather, PostCropVignetteMidpoint, PostCropVignetteRoundness, PostCropVignetteStyle

    # default values
    radius = 512.0
    intensity = 0.5
    center = [0.0, 0.0]
    falloff = 0.5
    found = False
    
    # only processing the new form here. Amount must be non-zero to proceed
    if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "PostCropVignetteAmount"):
        found = True
        intensity = -xmp.get_property_float(XMP_NS_CAMERA_RAW, "PostCropVignetteAmount") / 100.0  # flip polarity
        if abs(intensity) < 0.01:
            found = False
        else:
            if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "PostCropVignetteMidpoint"):
                falloff = xmp.get_property_float(XMP_NS_CAMERA_RAW, "PostCropVignetteMidpoint") * 10.0 # % to pixels, so unkown transform, guess at 10x
            if xmp.does_property_exist(XMP_NS_CAMERA_RAW, "PostCropVignetteFeather"):
                falloff = xmp.get_property_float(XMP_NS_CAMERA_RAW, "PostCropVignetteFeather") / 100.0
            # leave center as [0,0], which will then default to the center of the image

    if found:
        filterMap["filters"].append( {"CIVignetteEffect": {
                                                           "inputCenter": { "val": 0.0, "type": "CIAttributeTypePosition" },
                                                           "inputRadius": { "val": 512.0, "type": "CIAttributeTypeDistance"},
                                                           "inputIntensity": { "val": 0.5, "type": "CIAttributeTypeScalar"},
                                                           "inputFalloff": { "val": 0.5, "type": "CIAttributeTypeScalar"} }
                                    } )
        print ("...Vignette")



#----------------------------

# utility function to clamp a value between the suppied min and max values
def clamp(value, minv, maxv):
    return max(min(value, maxv), minv)

#----------------------------


# execute main function
main()
