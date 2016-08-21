//
//  AGAudioManager.m
//  Auragraph
//
//  Created by Spencer Salazar on 8/13/13.
//  Copyright (c) 2013 Spencer Salazar. All rights reserved.
//

#import "AGAudioManager.h"
#import "AGNode.h"
#import "AGAudioNode.h"
#import "AGTimer.h"

#import "mo_audio.h"

#import "Mutex.h"
#import "spstl.h"


static float g_audio_buf[1024];

@interface AGAudioManager ()
{
    sampletime t;
    
    list<AGAudioNode *> _renderers;
    Mutex _renderersMutex;
    list<AGTimer *> _timers;
    Mutex _timersMutex;
}

- (void)renderAudio:(Float32 *)buffer numFrames:(UInt32)numFrames;

@end


void audio_cb( Float32 * buffer, UInt32 numFrames, void * userData )
{
    [(__bridge AGAudioManager *)userData renderAudio:buffer numFrames:numFrames];
}

static AGAudioManager *g_audioManager;


@implementation AGAudioManager

@synthesize outputNode;

+ (id)instance
{
    return g_audioManager;
}

- (id)init
{
    if(self = [super init])
    {
        g_audioManager = self;
        
        t = 0;
        self.outputNode = NULL;
        
        memset(g_audio_buf, 0, sizeof(float)*1024);
        
        MoAudio::init(AGAudioNode::sampleRate(), AGAudioNode::bufferSize(), 2);
        MoAudio::start(audio_cb, (__bridge void *) self);
    }
    
    return self;
}

- (void)addRenderer:(AGAudioNode *)renderer
{
    _renderersMutex.lock();
    _renderers.push_back(renderer);
    _renderersMutex.unlock();
}

- (void)removeRenderer:(AGAudioNode *)renderer
{
    _renderersMutex.lock();
    _renderers.remove(renderer);
    _renderersMutex.unlock();
}

- (void)addTimer:(AGTimer *)timer
{
    _timersMutex.lock();
    _timers.push_back(timer);
    _timersMutex.unlock();
}

- (void)removeTimer:(AGTimer *)timer
{
    _timersMutex.lock();
    _timers.remove(timer);
    _timersMutex.unlock();
}


- (void)renderAudio:(Float32 *)buffer numFrames:(UInt32)numFrames
{
    memset(g_audio_buf, 0, sizeof(float)*1024);
    
    _timersMutex.lock();
    itmap(_timers, ^(AGTimer *&timer){
        float tf = ((float)t)/((float)AGAudioNode::sampleRate());
        float dtf = ((float)numFrames)/((float)AGAudioNode::sampleRate());
        timer->checkTimer(tf, dtf);
    });
    _timersMutex.unlock();
    
    _renderersMutex.lock();
    for(AGAudioNode *renderer : _renderers)
        renderer->renderAudio(t, NULL, g_audio_buf, numFrames);
    _renderersMutex.unlock();
    
    for(int i = 0; i < numFrames; i++)
    {
        buffer[i*2] = g_audio_buf[i];
        buffer[i*2+1] = g_audio_buf[i];
    }
    
    t += numFrames;
}


@end
