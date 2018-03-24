//
//  AGAudioSineWaveNode.cpp
//  Auragraph
//
//  Created by Spencer Salazar on 8/12/17.
//  Copyright © 2017 Spencer Salazar. All rights reserved.
//

#include "AGAudioNode.h"
#include "spdsp.h"

//------------------------------------------------------------------------------
// ### AGAudioSquareWaveNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioSquareWaveNode

class AGAudioSquareWaveNode : public AGAudioNode
{
public:
    
    enum Param
    {
        PARAM_OUTPUT = AUDIO_PARAM_LAST+1,
        PARAM_FREQ,
        PARAM_WIDTH,
        PARAM_PHASE,
    };
    
    class Manifest : public AGStandardNodeManifest<AGAudioSquareWaveNode>
    {
    public:
        string _type() const override { return "SquareWave"; };
        string _name() const override { return "SquareWave"; };
        string _description() const override { return "Standard square wave oscillator."; };
        
        vector<AGPortInfo> _inputPortInfo() const override
        {
            return {
                { PARAM_FREQ, "freq", 220, .doc = "Oscillator frequency." },
                { PARAM_WIDTH, "width", 0.5, 0, 1, .doc = "Pulse width of wave as fraction of full wavelength." },
                { AUDIO_PARAM_GAIN, "gain", 1, .doc = "Output gain." },
                { PARAM_PHASE, "phase", 1, 0, 0, AGPortInfo::LIN, .doc = "Oscillator phase." },
            };
        };
        
        vector<AGPortInfo> _editPortInfo() const override
        {
            return {
                { PARAM_FREQ, "freq", 220, .doc = "Oscillator frequency" },
                { PARAM_WIDTH, "width", 0.5, 0, 1, .doc = "Pulse width of wave as fraction of full wavelength." },
                { AUDIO_PARAM_GAIN, "gain", 1, .doc = "Output gain." }
            };
        };
        
        vector<AGPortInfo> _outputPortInfo() const override
        {
            return {
                { PARAM_OUTPUT, "output", .doc = "Output." }
            };
        }
        
        vector<GLvertex3f> _iconGeo() const override
        {
            float radius_x = 0.005*AGStyle::oldGlobalScale;
            float radius_y = radius_x * 0.66;
            
            // square wave shape
            vector<GLvertex3f> iconGeo = {
                { -radius_x, 0, 0 },
                { -radius_x, radius_y, 0 },
                { 0, radius_y, 0 },
                { 0, -radius_y, 0 },
                { radius_x, -radius_y, 0 },
                { radius_x, 0, 0 },
            };
            
            return iconGeo;
        };
        
        GLuint _iconGeoType() const override { return GL_LINE_STRIP; };
    };
    
    using AGAudioNode::AGAudioNode;
    
    void initFinal() override
    {
        m_phase = 0;
    }
    
    void receiveControl(int port, const AGControl &control) override
    {
        if(port == m_param2InputPort[PARAM_PHASE])
        {
            // hard-sync phase to control input
            m_phase = control.getFloat();
            // clear control
            // prevents upsampling to renderAudio phase vector
            clearControl(PARAM_PHASE);
        }
    }
    
    virtual void renderAudio(sampletime t, float *input, float *output, int nFrames, int chanNum, int nChans) override
    {
        if(t <= m_lastTime) { renderLast(output, nFrames, chanNum); return; }
        m_lastTime = t;
        pullInputPorts(t, nFrames);
        
        float *gainv = inputPortVector(AUDIO_PARAM_GAIN);
        float *freqv = inputPortVector(PARAM_FREQ);
        float *width = inputPortVector(PARAM_WIDTH);
        // if there are audio-rate phase inputs, then ignore m_phase value
        float phase_ctl = numInputsForPort(PARAM_PHASE, AGRate::RATE_AUDIO) > 0 ? 0.0f : 1.0f;
        float *phasev = inputPortVector(PARAM_PHASE);
        
        for(int i = 0; i < nFrames; i++)
        {
            m_outputBuffer[chanNum][i] = (m_phase < width[i] ? 1 : -1) * gainv[i];
            output[i] += m_outputBuffer[chanNum][i];
            
            m_phase = clipunit(m_phase*phase_ctl + freqv[i]/sampleRate() + phasev[i]);
        }
    }
    
private:
    float m_phase;
};

