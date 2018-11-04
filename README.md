<<<<<<< HEAD
# phixer

An app to apply filters to the camera stream or to a stored photo.

This project is based on an earlier app named 'FilterCam'. I had to re-write all of the underlying filter and graphics code because Apple is dropping support for OpenGL(ES). 
I was originally using the nifty GPUImage library from Brad Larsen, but now I am using the built in CIFilter classes and using Metal for graphics processing. 
Also, I had to change the name because of an App Store conflict.


## Basic Functionality

One day, I'll get around to adding screenshots, but the basic set of functionality includes:


- browse all available filters, assign ratings, hide/show, add to favourites. You can also change some of the parameters (the scalar or colour ones) and see the effect
    - there are currently ~190 filters defined and an additional 500+ colour transforms available (lookup filters) that are based on available Photoshop presets
    - because of this, filters are assigned to 'categories', and users can hide ones they don't want to see
- choose a sample image (used for browsing the filters). There are some built-in samples or you can use any photo
- choose a blend image, for those filters that combine multple images. There are some built-in blend images, or you can use any photo
- show the live camera feed and apply any filter. You can also save a photo with the filter applied
- edit an image from your photo albums. This is currently restricted to just applying a filter and saving the result, but eventually there will be a more fully featured editor


## Pods Used
I make fairly extensive use of the following pods:

- Neon: very useful functions for laying out views relative to each other
- Chameleon: a set of 'flat' colours and associated utilities that I use to colour the UI
- iCarousel: a horizontally scrolling list that can contain images etc.
- SwiftyBeaver: logging utilities
- SwiftyJSON: JSON parsing
- Cosmos: a star rating widget
=======
# FilterCam
IOS Swift app with live filters and editing capabilities

Note: I suspended work on this in mid-2017 - I had to work on a real job :-(

I will pick this up sometiome in 2018, but I have to move it to another project because of a naming conflict with an existing iOS app.
>>>>>>> master
