/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

/**
    Platform 
*/
module numem.platform;

version(OSX) enum IsAppleOS = true;
else version(iOS) enum IsAppleOS = true;
else version(TVOS) enum IsAppleOS = true;
else version(WatchOS) enum IsAppleOS = true;
else version(VisionOS) enum IsAppleOS = true;
else enum IsAppleOS = false;