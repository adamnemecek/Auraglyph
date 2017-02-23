//
//  AGControlSequencerNode.hpp
//  Auragraph
//
//  Created by Spencer Salazar on 3/12/16.
//  Copyright © 2016 Spencer Salazar. All rights reserved.
//

#pragma once

#include "AGControlNode.h"
#include "AGTimer.h"
#include <list>
#include <vector>

class AGControlSequencerNode : public AGControlNode
{
public:
    
    enum PARAM
    {
        PARAM_ADVANCE,
        PARAM_BPM,
    };
    
    class Manifest : public AGStandardNodeManifest<AGControlSequencerNode>
    {
    public:
        string _type() const override;
        string _name() const override;
        string _description() const override { return "Discrete step sequencer for control values."; };
        vector<AGPortInfo> _inputPortInfo() const override;
        vector<AGPortInfo> _editPortInfo() const override;
        vector<GLvertex3f> _iconGeo() const override;
        GLuint _iconGeoType() const override;
    };
    
    using AGControlNode::AGControlNode;
    
    void initFinal() override;
    void deserializeFinal(const AGDocument::Node &docNode) override;
    
    virtual int numOutputPorts() const override;
    virtual void editPortValueChanged(int paramId) override;
    
    virtual AGUINodeEditor *createCustomEditor() override;
    
    int currentStep();
    int numSequences();
    void setNumSequences(int num);
    int numSteps();
    void setNumSteps(int num);
    
    void setStepValue(int seq, int step, float value);
    float getStepValue(int seq, int step);
    
    void receiveControl(int port, const AGControl &control) override;
    
    float bpm();
    void setBpm(float bpm);
    
    AGDocument::Node serialize() override;
    
private:
    static AGNodeInfo *s_nodeInfo;
    
    AGTimer m_timer;
    
    int m_pos;
    int m_numSteps;
    Mutex m_seqLock;
    std::vector<std::vector<float> > m_sequence;
    
    void updateStep();
};

