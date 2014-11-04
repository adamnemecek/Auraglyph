//
//  AGAudioNode.h
//  Auragraph
//
//  Created by Spencer Salazar on 8/14/13.
//  Copyright (c) 2013 Spencer Salazar. All rights reserved.
//

#ifndef __Auragraph__AGAudioNode__
#define __Auragraph__AGAudioNode__

#import "Geometry.h"
#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>
#import "ShaderHelper.h"
#import <list>
#import <vector>
#import <string>
#import "AGNode.h"

using namespace std;


class AGAudioOutputNode : public AGAudioNode
{
public:
    static void initialize();
    
    AGAudioOutputNode(GLvertex3f pos);
    
    virtual int numOutputPorts() const { return 0; }
    virtual int numInputPorts() const { return 1; }
    
    virtual void renderAudio(sampletime t, float *input, float *output, int nFrames);
    
    static void renderIcon();
    static AGAudioNode *create(const GLvertex3f &pos);
    
private:
    static AGNodeInfo *s_audioNodeInfo;
};


class AGAudioNodeManager
{
public:
    static const AGAudioNodeManager &instance();
    
    struct AudioNodeType
    {
        // TODO: make class
        AudioNodeType(std::string _name, void (*_initialize)(), void (*_renderIcon)(),
                      AGAudioNode *(*_createNode)(const GLvertex3f &pos)) :
        name(_name),
        initialize(_initialize),
        renderIcon(_renderIcon),
        createNode(_createNode)
        { }
        
        std::string name;
        void (*initialize)();
        void (*renderIcon)();
        AGAudioNode *(*createNode)(const GLvertex3f &pos);
    };
    
    const std::vector<AudioNodeType *> &nodeTypes() const;
    void renderNodeTypeIcon(AudioNodeType *type) const;
    AGAudioNode * createNodeType(AudioNodeType *type, const GLvertex3f &pos) const;
    
private:
    static AGAudioNodeManager * s_instance;
    
    std::vector<AudioNodeType *> m_audioNodeTypes;
    
    AGAudioNodeManager();
};



#endif /* defined(__Auragraph__AGAudioNode__) */
