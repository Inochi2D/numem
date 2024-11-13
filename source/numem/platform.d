/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Platform 
*/
module numem.platform;

mixin template CheckOS() {
    version(OSX) version = AppleOS;
    else version(iOS) version = AppleOS;
    else version(TVOS) version = AppleOS;
    else version(WatchOS) version = AppleOS;
    else version(VisionOS) version = AppleOS;
}