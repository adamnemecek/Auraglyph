//
//  AGControlSequencerNode.hpp
//  Auragraph
//
//  Created by Spencer Salazar on 3/12/16.
//  Copyright © 2016 Spencer Salazar. All rights reserved.
//

#ifndef AGControlSequencerNode_hpp
#define AGControlSequencerNode_hpp

#import "AGControlNode.h"
#import "AGTimer.h"
#import <list>
#import <vector>

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
        vector<AGPortInfo> _inputPortInfo() const override;
        vector<AGPortInfo> _editPortInfo() const override;
        vector<GLvertex3f> _iconGeo() const override;
        GLuint _iconGeoType() const override;
    };
    
//    using AGControlNode::AGControlNode;
    
    AGControlSequencerNode(const AGNodeManifest *mf, const GLvertex3f &pos);
    AGControlSequencerNode(const AGNodeManifest *mf, const AGDocument::Node &docNode);
    ~AGControlSequencerNode();
    
    void initFinal() override;
    
    virtual int numOutputPorts() const override;
    virtual void editPortValueChanged(int paramId) override;
    
    virtual AGUINodeEditor *createCustomEditor() override;
    
    int currentStep();
    int numSequences();
    int numSteps();
    
    void setStepValue(int seq, int step, float value);
    float getStepValue(int seq, int step);
    
    float bpm();
    void setBpm(float bpm);
    
    AGDocument::Node serialize() override;
    
private:
    static AGNodeInfo *s_nodeInfo;
    
    AGTimer *m_timer;
    
    int m_pos;
    int m_numSteps;
    std::vector<std::vector<float> > m_sequence;
    
    void updateStep();
};


#endif /* AGControlSequencerNode_hpp */
