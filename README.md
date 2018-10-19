# phixer

An app to apply filters to the camera stream or to a stored photo.

This project is based on an earlier app named 'FilterCam'. I had to re-write all of the underlying filter and graphics code because Apple is dropping support for OpenGL(ES). 
I was originally using the nifty GPUImage library from Brad Larsen, but now I am using the built in CIFilter classes and using Metal for graphics processing. 
Also, I had to change the name because of an App Store conflict.


