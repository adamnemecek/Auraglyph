//
//  AGMidiConnectionListener.h
//  Auragraph
//
//  Created by Andrew Piepenbrink on 7/20/17.
//  Copyright © 2017 Spencer Salazar. All rights reserved.
//
//  Parts of this code are based on ofxMidi by Dan Wilcox.
//  See https://github.com/danomatika/ofxMidi for documentation

#ifndef AGMidiConnectionListener_h
#define AGMidiConnectionListener_h

#include <string>

using namespace std;

class AGMidiConnectionListener {
    
public:
    
    AGMidiConnectionListener() {}
    virtual ~AGMidiConnectionListener() {}
    
    virtual void midiInputAdded(string name, bool isNetwork=false);
    virtual void midiInputRemoved(string name, bool isNetwork=false);
    
    virtual void midiOutputAdded(string name, bool isNetwork=false);
    virtual void midiOutputRemoved(string name, bool isNetwork=false);
};

#endif /* AGMidiConnectionListener_h */
