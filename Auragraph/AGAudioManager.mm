//
//  AGAudioManager.m
//  Auragraph
//
//  Created by Spencer Salazar on 8/13/13.
//  Copyright (c) 2013 Spencer Salazar. All rights reserved.
//

#import "AGAudioManager.h"
#import "AGNode.h"
#import "mo_audio.h"


static float g_audio_buf[1024];

@interface AGAudioManager ()

- (void)renderAudio:(Float32 *)buffer numFrames:(UInt32)numFrames;

@end

void audio_cb( Float32 * buffer, UInt32 numFrames, void * userData )
{
    [(__bridge AGAudioManager *)userData renderAudio:buffer numFrames:numFrames];
}

@implementation AGAudioManager

@synthesize outputNode;

- (id)init
{
    if(self = [super init])
    {
        self.outputNode = NULL;
        
        memset(g_audio_buf, 0, sizeof(float)*1024);
        
        MoAudio::init(AGAudioNode::sampleRate(), 256, 2);
        MoAudio::start(audio_cb, (__bridge void *) self);
    }
    
    return self;
}


- (void)renderAudio:(Float32 *)buffer numFrames:(UInt32)numFrames
{
    if(self.outputNode)
    {
        self.outputNode->renderAudio(NULL, g_audio_buf, numFrames);
    }
    
    for(int i = 0; i < numFrames; i++)
    {
        buffer[i*2] = g_audio_buf[i];
        buffer[i*2+1] = g_audio_buf[i];
    }
}


@end
