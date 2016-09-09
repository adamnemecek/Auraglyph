//
//  AGCompositeNode.hpp
//  Auragraph
//
//  Created by Spencer Salazar on 8/24/16.
//  Copyright © 2016 Spencer Salazar. All rights reserved.
//

#ifndef AGCompositeNode_h
#define AGCompositeNode_h


#include "AGAudioNode.h"
#include "AGAudioCapturer.h"
#include "AGAudioOutputDestination.h"
#include <list>

using namespace std;


//------------------------------------------------------------------------------
// ### AGAudioCompositeNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioCompositeNode


class AGAudioCompositeNode : public AGAudioNode, public AGAudioOutputDestination
{
public:
    
    class Manifest : public AGStandardNodeManifest<AGAudioCompositeNode>
    {
    public:
        string _type() const override { return "Composite"; };
        string _name() const override { return "Composite"; };
        
        vector<AGPortInfo> _inputPortInfo() const override
        {
            return {
                { "input", true, true }
            };
        };
        
        vector<AGPortInfo> _editPortInfo() const override
        {
            return {
                { "gain", true, true }
            };
        };
        
        vector<GLvertex3f> _iconGeo() const override
        {
            int NUM_PTS = 32;
            vector<GLvertex3f> iconGeo(NUM_PTS);
            
            float radius = 0.005*AGStyle::oldGlobalScale;
            for(int i = 0; i < NUM_PTS; i++)
            {
                float t = ((float)i)/((float)(NUM_PTS-1));
                float x = radius*cos(2*M_PI*t);
                float y = radius*sin(2*M_PI*t);
                iconGeo[i] = GLvertex3f(x, y, 0);
            }
            
            return iconGeo;
        };
        
        GLuint _iconGeoType() const override { return GL_LINE_STRIP; };
    };
    
    using AGAudioNode::AGAudioNode;
    
    void setDefaultPortValues() override
    {
        m_gain = 1;
    }
    
    virtual int numOutputPorts() const override;
    
    virtual void setEditPortValue(int port, float value) override;
    virtual void getEditPortValue(int port, float &value) const override;
    
    virtual void renderAudio(sampletime t, float *input, float *output, int nFrames) override;
    
//    void addOutputNode(AGAudioNode *outputNode);
//    void addInputNode(AGAudioCapturer *inputNode);
    
    void addSubnode(AGNode *subnode);
    void removeSubnode(AGNode *subnode);
    
    void addOutput(AGAudioRenderer *renderer) override;
    void removeOutput(AGAudioRenderer *renderer) override;

private:
    
    Mutex m_outputsMutex;
    list<AGAudioRenderer *> m_outputs;
    Mutex m_inputsMutex;
    list<AGAudioCapturer *> m_inputNodes;
    
    list<AGNode *> m_subnodes;
};


#endif /* AGCompositeNode_h */
