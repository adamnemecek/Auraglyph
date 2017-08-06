//
//  AGControlMidiCCIn.cpp
//  Auragraph
//
//  Created by Andrew Piepenbrink on 7/20/17.
//  Copyright © 2017 Spencer Salazar. All rights reserved.
//
//  Parts of this code are based on ofxMidi by Dan Wilcox.
//  See https://github.com/danomatika/ofxMidi for documentation

#include "AGStyle.h"
#include "AGControlMidiCCIn.h"
#include "AGPGMidiSourceDelegate.h"

#include <iostream>

//------------------------------------------------------------------------------
// ### AGControlMidiCCIn ###
//------------------------------------------------------------------------------
#pragma mark - AGControlMidiCCIn

// PIMPL wrapper from http://stackoverflow.com/questions/7132755/wrapping-objective-c-in-objective-c-c
struct AGControlMidiCCIn::InputDelegate {
    AGPGMidiSourceDelegate *d; ///< Obj-C input delegate
};

// Definition needed here since portList is static
vector<string> AGControlMidiCCIn::portList;

void AGControlMidiCCIn::initFinal()
{
    // setup Obj-C interface to PGMidi
    inputDelegate = new InputDelegate;
    inputDelegate->d = [[AGPGMidiSourceDelegate alloc] init];
    [inputDelegate->d setInputPtr:(AGControlMidiInput *) this];
    
    // Go for it!
    attachToAllExistingSources();
}

AGControlMidiCCIn::~AGControlMidiCCIn()
{
    detachFromAllExistingSources();
    delete inputDelegate;
}

void AGControlMidiCCIn::attachToAllExistingSources()
{
    PGMidi *midi = AGPGMidiContext::getMidi();
    for (PGMidiSource *source in midi.sources)
    {
        [source addDelegate:inputDelegate->d];
    }
}

void AGControlMidiCCIn::detachFromAllExistingSources()
{
    PGMidi *midi = AGPGMidiContext::getMidi();
    for (PGMidiSource *source in midi.sources)
    {
        [source removeDelegate:inputDelegate->d];
    }
    
}

void AGControlMidiCCIn::editPortValueChanged(int paramId)
{
    // XXX when we implement channel filtering we will need to address this
}

void AGControlMidiCCIn::messageReceived(double deltatime, vector<unsigned char> *message)
{
    // Examine our first byte to determine the type of message
    uint8_t chr = message->at(0);
    
    chr &= 0xF0; // Ignore channel information for now by clearing the lower nibble
    
    static bool noteStatus = false; // Kludgy flag for legato tracking
    static uint8_t curNote = 0x00; //
    
    if(chr == 0x80) { }// Note off
    else if(chr == 0x90) { }// Note on
    else if(chr == 0xA0) { } // Mmmm... polyphonic aftertouch
    else if(chr == 0xB0) // CC
    {
        pushControl(0, AGControl(message->at(1))); // CC number
        pushControl(1, AGControl(message->at(2)));; // CC value
    }
}

void AGControlMidiCCIn::listPorts()
{
    PGMidi *midi = AGPGMidiContext::getMidi();
    int count = [midi.sources count];
    cout << count << " ports available";
    for(NSUInteger i = 0; i < count; ++i) {
        PGMidiSource *source = [midi.sources objectAtIndex:i];
        cout << i << ": " << [source.name UTF8String] << endl;
    }
}

vector<string>& AGControlMidiCCIn::getPortList()
{
    PGMidi *midi = AGPGMidiContext::getMidi();
    portList.clear();
    for(PGMidiSource *source in midi.sources) {
        portList.push_back([source.name UTF8String]);
    }
    return portList;
}

int AGControlMidiCCIn::getNumPorts()
{
    return [AGPGMidiContext::getMidi().sources count];
}

string AGControlMidiCCIn::getPortName(unsigned int portNumber)
{
    
    PGMidi *midi = AGPGMidiContext::getMidi();
    
    // handle OBJ-C exceptions
    @try {
        PGMidiSource *source = [midi.sources objectAtIndex:portNumber];
        return [source.name UTF8String];
    }
    @catch(NSException *ex) {
        cout << "couldn't get name for port " << portNumber
        << " " << [ex.name UTF8String] << ": " << [ex.reason UTF8String] << endl;
    }
    return "";
}

bool AGControlMidiCCIn::openPort(unsigned int portNumber)
{
    
    PGMidi *midi = AGPGMidiContext::getMidi();
    PGMidiSource *source = nil;
    
    // handle OBJ-C exceptions
    @try {
        source = [midi.sources objectAtIndex:portNumber];
    }
    @catch(NSException *ex) {
        cout << "couldn't open port " << portNumber << " " << [ex.name UTF8String]
        << ": " << [ex.reason UTF8String] << endl;
        return false;
    }
    [source addDelegate:inputDelegate->d];
    portNum = portNumber;
    portName = [source.name UTF8String];
    bOpen = true;
    cout << "opened port " << portNum << " " << portName << endl;
    return true;
}

bool AGControlMidiCCIn::openPort(string deviceName)
{
    
    PGMidi *midi = AGPGMidiContext::getMidi();
    
    // iterate through MIDI ports, find requested device
    int port = -2;
    for(NSUInteger i = 0; i < [midi.sources count]; ++i) {
        PGMidiSource *source = [midi.sources objectAtIndex:i];
        if([source.name UTF8String] == deviceName) {
            port = i;
            break;
        }
    }
    
    // bail if not found
    if(port == -1) {
        cout << "port \"" << deviceName << "\" is not available" << endl;
        return false;
    }
    
    return openPort(port);
}

bool AGControlMidiCCIn::openVirtualPort(string portName)
{
    cout << "couldn't open virtual port \"" << portName << endl;
    cout << "virtual ports are currently not supported on iOS" << endl;
    return false;
}

void AGControlMidiCCIn::closePort()
{
    
    if(bOpen) {
        cout << "closing port " << portNum << " " << portName << endl;
        
        // sometimes the source may already have been removed in PGMidi, so make
        // sure we have a valid index otherwise the app will crash
        PGMidi *midi = AGPGMidiContext::getMidi();
        if(portNum < midi.sources.count) {
            PGMidiSource *source = [midi.sources objectAtIndex:portNum];
            [source removeDelegate:inputDelegate->d];
        }
    }
    
    portNum = -1;
    portName = "";
    bOpen = false;
    bVirtual = false;
}

void AGControlMidiCCIn::ignoreTypes(bool midiSysex, bool midiTiming, bool midiSense)
{
    inputDelegate->d.bIgnoreSysex = midiSysex;
    inputDelegate->d.bIgnoreTiming = midiTiming;
    inputDelegate->d.bIgnoreSense = midiSense;
}

void AGControlMidiCCIn::setConnectionListener(AGMidiConnectionListener * listener)
{
    AGPGMidiContext::setConnectionListener(listener);
}

void AGControlMidiCCIn::clearConnectionListener()
{
    AGPGMidiContext::clearConnectionListener();
}

void AGControlMidiCCIn::enableNetworking()
{
    AGPGMidiContext::enableNetwork();
}

