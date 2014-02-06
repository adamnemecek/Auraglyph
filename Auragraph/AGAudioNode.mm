//
//  AGAudioNode.cpp
//  Auragraph
//
//  Created by Spencer Salazar on 8/14/13.
//  Copyright (c) 2013 Spencer Salazar. All rights reserved.
//

#include "AGAudioNode.h"
#include "AGNode.h"


bool AGAudioNode::s_init = false;
GLuint AGAudioNode::s_vertexArray = 0;
GLuint AGAudioNode::s_vertexBuffer = 0;
GLuint AGAudioNode::s_geoSize = 0;
int AGAudioNode::s_sampleRate = 44100;

AGAudioNodeInfo *AGAudioOutputNode::s_audioNodeInfo = NULL;
AGAudioNodeInfo *AGAudioSineWaveNode::s_audioNodeInfo = NULL;
AGAudioNodeInfo *AGAudioSquareWaveNode::s_audioNodeInfo = NULL;
AGAudioNodeInfo *AGAudioSawtoothWaveNode::s_audioNodeInfo = NULL;
AGAudioNodeInfo *AGAudioTriangleWaveNode::s_audioNodeInfo = NULL;
AGAudioNodeInfo *AGAudioADSRNode::s_audioNodeInfo = NULL;

//------------------------------------------------------------------------------
// ### AGAudioNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioNode

void AGAudioNode::initializeAudioNode()
{
    initalizeNode();
    
    if(!s_init)
    {
        s_init = true;
        
        // generate circle
        s_geoSize = 64;
        GLvertex3f *geo = new GLvertex3f[s_geoSize];
        float radius = 0.01;
        for(int i = 0; i < s_geoSize; i++)
        {
            float theta = 2*M_PI*((float)i)/((float)(s_geoSize));
            geo[i] = GLvertex3f(radius*cosf(theta), radius*sinf(theta), 0);
        }
        
        genVertexArrayAndBuffer(s_geoSize, geo, s_vertexArray, s_vertexBuffer);
        
        delete[] geo;
        geo = NULL;
        
        AGAudioSineWaveNode::initialize();
    }
}

AGAudioNode::AGAudioNode(GLvertex3f pos) :
AGNode(pos)
{
    initializeAudioNode();
    
    m_gain = 1;
    
    m_radius = 0.01;
    m_portRadius = 0.01 * 0.2;
    
    m_inputActivation = m_outputActivation = 0;
    m_activation = 0;
    
    m_iconVertexArray = 0;
    m_iconGeoSize = 0;
    m_iconGeoType = 0;
    
    m_inputPortBuffer = NULL;
}

AGAudioNode::~AGAudioNode()
{
    if(m_inputPortBuffer)
    {
        for(int i = 0; i < numInputPorts(); i++)
        {
            if(m_inputPortBuffer[i])
            {
                delete[] m_inputPortBuffer[i];
                m_inputPortBuffer[i] = NULL;
            }
        }
        
        delete[] m_inputPortBuffer;
        m_inputPortBuffer = NULL;
    }
}

void AGAudioNode::renderAudio(float *input, float *output, int nFrames)
{
}

void AGAudioNode::update(float t, float dt)
{
    GLKMatrix4 projection = projectionMatrix();
    GLKMatrix4 modelView = globalModelViewMatrix();
    
    modelView = GLKMatrix4Translate(modelView, m_pos.x, m_pos.y, m_pos.z);
    
    m_normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelView), NULL);
    m_modelViewProjectionMatrix = GLKMatrix4Multiply(projection, modelView);
}

void AGAudioNode::render()
{
    GLcolor4f color = GLcolor4f::white;
    
    // draw base outline
    glBindVertexArrayOES(s_vertexArray);
    
    glVertexAttrib4fv(GLKVertexAttribColor, (const float *) &color);
    glVertexAttrib3f(GLKVertexAttribNormal, 0, 0, 1);
    
    glUseProgram(s_program);
    
    glUniformMatrix3fv(s_uniformNormalMatrix, 1, 0, m_normalMatrix.m);

    if(m_activation)
    {
        float scale = 0.975;
        
        GLKMatrix4 projection = projectionMatrix();
        GLKMatrix4 modelView = globalModelViewMatrix();
        
        modelView = GLKMatrix4Translate(modelView, m_pos.x, m_pos.y, m_pos.z);
        GLKMatrix4 modelViewInner = GLKMatrix4Scale(modelView, scale, scale, scale);
        GLKMatrix4 mvp = GLKMatrix4Multiply(projection, modelViewInner);
        glUniformMatrix4fv(s_uniformMVPMatrix, 1, 0, mvp.m);
        
        glLineWidth(4.0f);
        glDrawArrays(GL_LINE_LOOP, 0, s_geoSize);
        
        GLKMatrix4 modelViewOuter = GLKMatrix4Scale(modelView, 1.0/scale, 1.0/scale, 1.0/scale);
        mvp = GLKMatrix4Multiply(projection, modelViewOuter);
        glUniformMatrix4fv(s_uniformMVPMatrix, 1, 0, mvp.m);
        
        glLineWidth(4.0f);
        glDrawArrays(GL_LINE_LOOP, 0, s_geoSize);
    }
    else
    {
        glUniformMatrix4fv(s_uniformMVPMatrix, 1, 0, m_modelViewProjectionMatrix.m);
        glUniformMatrix3fv(s_uniformNormalMatrix, 1, 0, m_normalMatrix.m);
        
        glLineWidth(4.0f);
        glDrawArrays(GL_LINE_LOOP, 0, s_geoSize);
    }
    
    if(numOutputPorts())
    {
        // draw output port
        GLKMatrix4 mvpOutputPort = GLKMatrix4Translate(m_modelViewProjectionMatrix, m_radius, 0, 0);
        mvpOutputPort = GLKMatrix4Scale(mvpOutputPort, 0.2, 0.2, 1);
        
        glUniformMatrix4fv(s_uniformMVPMatrix, 1, 0, mvpOutputPort.m);
        if(m_outputActivation > 0)      color = GLcolor4f(0, 1, 0, 1);
        else if(m_outputActivation < 0) color = GLcolor4f(1, 0, 0, 1);
        else                            color = GLcolor4f(1, 1, 1, 1);
        
        glVertexAttrib4fv(GLKVertexAttribColor, (const float *) &color);
        
        glLineWidth(2.0f);
        glDrawArrays(GL_LINE_LOOP, 0, s_geoSize);
    }
    
    if(numInputPorts())
    {
        // draw input port
        GLKMatrix4 mvpInputPort = GLKMatrix4Translate(m_modelViewProjectionMatrix, -m_radius, 0, 0);
        mvpInputPort = GLKMatrix4Scale(mvpInputPort, 0.2, 0.2, 1);
        
        glUniformMatrix4fv(s_uniformMVPMatrix, 1, 0, mvpInputPort.m);
        if(m_inputActivation > 0)      color = GLcolor4f(0, 1, 0, 1);
        else if(m_inputActivation < 0) color = GLcolor4f(1, 0, 0, 1);
        else                           color = GLcolor4f(1, 1, 1, 1);
        glVertexAttrib4fv(GLKVertexAttribColor, (const float *) &color);
        
        glLineWidth(2.0f);
        glDrawArrays(GL_LINE_LOOP, 0, s_geoSize);
    }
    
    // render icon
    if(m_iconVertexArray)
    {
        // draw base outline
        glBindVertexArrayOES(m_iconVertexArray);
        
        glVertexAttrib4fv(GLKVertexAttribColor, (const float *) &GLcolor4f::white);
        glVertexAttrib3f(GLKVertexAttribNormal, 0, 0, 1);
        
        glUniformMatrix4fv(s_uniformMVPMatrix, 1, 0, m_modelViewProjectionMatrix.m);
        glUniformMatrix3fv(s_uniformNormalMatrix, 1, 0, m_normalMatrix.m);

        glLineWidth(2.0f);
        glDrawArrays(m_iconGeoType, 0, m_iconGeoSize);
    }
    
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}


AGNode::HitTestResult AGAudioNode::hit(const GLvertex3f &hit)
{
    float x, y;
    
    if(numInputPorts())
    {
        // check input port
        x = hit.x - (m_pos.x - m_radius);
        y = hit.y - m_pos.y;
        if(x*x + y*y <= m_portRadius*m_portRadius)
        {
            return HIT_INPUT_NODE;
        }
    }
    
    if(numOutputPorts())
    {
        // check output port
        x = hit.x - (m_pos.x + m_radius);
        y = hit.y - m_pos.y;
        if(x*x + y*y <= m_portRadius*m_portRadius)
        {
            return HIT_OUTPUT_NODE;
        }
    }
    
    // check whole node
    x = hit.x - m_pos.x;
    y = hit.y - m_pos.y;
    if(x*x + y*y <= m_radius*m_radius)
    {
        return HIT_MAIN_NODE;
    }
    
    return HIT_NONE;
}

void AGAudioNode::unhit()
{
    //m_hitInput = m_hitOutput = false;
}

GLvertex3f AGAudioNode::positionForInboundConnection(AGConnection * connection) const
{
    return GLvertex3f(m_pos.x - m_radius, m_pos.y, m_pos.z);
}

GLvertex3f AGAudioNode::positionForOutboundConnection(AGConnection * connection) const
{
    return GLvertex3f(m_pos.x + m_radius, m_pos.y, m_pos.z);
}

void AGAudioNode::allocatePortBuffers()
{
    if(numInputPorts() > 0)
    {
        m_inputPortBuffer = new float*[numInputPorts()];
        for(int i = 0; i < numInputPorts(); i++)
        {
            if(m_inputPortInfo[i].canConnect)
            {
                m_inputPortBuffer[i] = new float[bufferSize()];
                memset(m_inputPortBuffer[i], 0, sizeof(float)*bufferSize());
            }
            else
            {
                m_inputPortBuffer[i] = NULL;
            }
        }
    }
    else
    {
        m_inputPortBuffer = NULL;
    }
}

void AGAudioNode::pullInputPorts(int nFrames)
{
    this->lock();
    
    if(m_inputPortBuffer != NULL)
    {
        for(int i = 0; i < numInputPorts(); i++)
        {
            if(m_inputPortBuffer[i] != NULL)
                memset(m_inputPortBuffer[i], 0, nFrames*sizeof(float));
        }
    }
    
    for(std::list<AGConnection *>::iterator c = m_inbound.begin(); c != m_inbound.end(); c++)
    {
        AGConnection * conn = *c;
        if(conn->rate() == RATE_AUDIO)
        {
            assert(m_inputPortBuffer && m_inputPortBuffer[conn->dstPort()]);
            ((AGAudioNode *) conn->src())->renderAudio(NULL, m_inputPortBuffer[conn->dstPort()], nFrames);
        }
        //else TODO
    }
    
    this->unlock();
}

//------------------------------------------------------------------------------
// ### AGAudioOutputNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioOutputNode

AGAudioOutputNode::AGAudioOutputNode(GLvertex3f pos) : AGAudioNode(pos)
{
    initialize();
    
    m_inputPortInfo = &s_audioNodeInfo->portInfo[0];
    m_iconVertexArray = s_audioNodeInfo->iconVertexArray;
    m_iconGeoSize = s_audioNodeInfo->iconGeoSize;
    m_iconGeoType = s_audioNodeInfo->iconGeoType;
}

void AGAudioOutputNode::initialize()
{
    initializeAudioNode();
    
    if(s_audioNodeInfo == NULL)
    {
        s_audioNodeInfo = new AGAudioNodeInfo;
        // s_initAudioOutputNode = true;
        
        s_audioNodeInfo->iconGeoSize = 8;
        GLvertex3f *iconGeo = new GLvertex3f[s_audioNodeInfo->iconGeoSize];
        s_audioNodeInfo->iconGeoType = GL_LINE_STRIP;
        float radius = 0.005;
        
        // speaker icon
        iconGeo[0] = GLvertex3f(-radius*0.5*0.16, radius*0.5, 0);
        iconGeo[1] = GLvertex3f(-radius*0.5, radius*0.5, 0);
        iconGeo[2] = GLvertex3f(-radius*0.5, -radius*0.5, 0);
        iconGeo[3] = GLvertex3f(-radius*0.5*0.16, -radius*0.5, 0);
        iconGeo[4] = GLvertex3f(radius*0.5, -radius, 0);
        iconGeo[5] = GLvertex3f(radius*0.5, radius, 0);
        iconGeo[6] = GLvertex3f(-radius*0.5*0.16, radius*0.5, 0);
        iconGeo[7] = GLvertex3f(-radius*0.5*0.16, -radius*0.5, 0);
        
        genVertexArrayAndBuffer(s_audioNodeInfo->iconGeoSize, iconGeo,
                                s_audioNodeInfo->iconVertexArray,
                                s_audioNodeInfo->iconVertexBuffer);
        
        delete[] iconGeo;
        iconGeo = NULL;
        
        s_audioNodeInfo->portInfo.push_back({ "input", true, false });
    }
}


void AGAudioOutputNode::renderAudio(float *input, float *output, int nFrames)
{
    for(std::list<AGConnection *>::iterator i = m_inbound.begin(); i != m_inbound.end(); i++)
    {
        ((AGAudioNode *)(*i)->src())->renderAudio(input, output, nFrames);
    }
}


//------------------------------------------------------------------------------
// ### AGAudioSineWaveNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioSineWaveNode

void AGAudioSineWaveNode::initialize()
{
    initializeAudioNode();
    
    if(s_audioNodeInfo == NULL)
    {
        s_audioNodeInfo = new AGAudioNodeInfo;
        
        // generate geometry
        s_audioNodeInfo->iconGeoSize = 32;
        GLvertex3f *iconGeo = new GLvertex3f[s_audioNodeInfo->iconGeoSize];
        s_audioNodeInfo->iconGeoType = GL_LINE_STRIP;
        float radius = 0.005;
        for(int i = 0; i < s_audioNodeInfo->iconGeoSize; i++)
        {
            float t = ((float)i)/((float)(s_audioNodeInfo->iconGeoSize-1));
            float x = (t*2-1) * radius;
            float y = radius*0.66*sinf(t*M_PI*2);
            
            iconGeo[i] = GLvertex3f(x, y, 0);
        }
        
        genVertexArrayAndBuffer(s_audioNodeInfo->iconGeoSize, iconGeo,
                                s_audioNodeInfo->iconVertexArray,
                                s_audioNodeInfo->iconVertexBuffer);
        
        delete[] iconGeo;
        iconGeo = NULL;

        s_audioNodeInfo->portInfo.push_back({ "freq", true, true });
        s_audioNodeInfo->portInfo.push_back({ "gain", true, true });
    }
}

AGAudioSineWaveNode::AGAudioSineWaveNode(GLvertex3f pos) : AGAudioNode(pos)
{
    initialize();
    
    m_inputPortInfo = &s_audioNodeInfo->portInfo[0];
    
    m_iconVertexArray = s_audioNodeInfo->iconVertexArray;
    m_iconGeoSize = s_audioNodeInfo->iconGeoSize;
    m_iconGeoType = s_audioNodeInfo->iconGeoType;
    
    m_freq = 220;
    m_phase = 0;
    
    allocatePortBuffers();
}

void AGAudioSineWaveNode::setInputPortValue(int port, float value)
{
    switch(port)
    {
        case 0: m_freq = value; break;
        case 1: m_gain = value; break;
    }
}

void AGAudioSineWaveNode::getInputPortValue(int port, float &value) const
{
    switch(port)
    {
        case 0: value = m_freq; break;
        case 1: value = m_gain; break;
    }
}

void AGAudioSineWaveNode::renderAudio(float *input, float *output, int nFrames)
{
    pullInputPorts(nFrames);
    
    for(int i = 0; i < nFrames; i++)
    {
        output[i] += sinf(m_phase*2.0*M_PI) * (m_gain + m_inputPortBuffer[1][i]);
        m_phase += (m_freq + m_inputPortBuffer[0][i])/sampleRate();
        while(m_phase >= 1.0) m_phase -= 1.0;
    }
}

void AGAudioSineWaveNode::renderIcon()
{
    initialize();
    
    // render icon
    glBindVertexArrayOES(s_audioNodeInfo->iconVertexArray);
    
    glLineWidth(2.0);
    glDrawArrays(s_audioNodeInfo->iconGeoType, 0, s_audioNodeInfo->iconGeoSize);
    
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

AGAudioNode *AGAudioSineWaveNode::create(const GLvertex3f &pos)
{
    return new AGAudioSineWaveNode(pos);
}

//------------------------------------------------------------------------------
// ### AGAudioSquareWaveNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioSquareWaveNode

void AGAudioSquareWaveNode::initialize()
{
    initializeAudioNode();
    
    if(s_audioNodeInfo == NULL)
    {
        s_audioNodeInfo = new AGAudioNodeInfo;
        
        // generate geometry
        s_audioNodeInfo->iconGeoSize = 6;
        GLvertex3f * iconGeo = new GLvertex3f[s_audioNodeInfo->iconGeoSize];
        s_audioNodeInfo->iconGeoType = GL_LINE_STRIP;
        float radius_x = 0.005;
        float radius_y = radius_x * 0.66;
        
        // square wave shape
        iconGeo[0] = GLvertex3f(-radius_x, 0, 0);
        iconGeo[1] = GLvertex3f(-radius_x, radius_y, 0);
        iconGeo[2] = GLvertex3f(0, radius_y, 0);
        iconGeo[3] = GLvertex3f(0, -radius_y, 0);
        iconGeo[4] = GLvertex3f(radius_x, -radius_y, 0);
        iconGeo[5] = GLvertex3f(radius_x, 0, 0);
        
        genVertexArrayAndBuffer(s_audioNodeInfo->iconGeoSize, iconGeo,
                                s_audioNodeInfo->iconVertexArray,
                                s_audioNodeInfo->iconVertexBuffer);
        
        delete[] iconGeo;
        iconGeo = NULL;
        
        s_audioNodeInfo->portInfo.push_back({ "freq", true, true });
        s_audioNodeInfo->portInfo.push_back({ "gain", true, true });
    }
}

AGAudioSquareWaveNode::AGAudioSquareWaveNode(GLvertex3f pos) : AGAudioNode(pos)
{
    initialize();
    
    m_inputPortInfo = &s_audioNodeInfo->portInfo[0];
    
    m_iconVertexArray = s_audioNodeInfo->iconVertexArray;
    m_iconGeoSize = s_audioNodeInfo->iconGeoSize;
    m_iconGeoType = s_audioNodeInfo->iconGeoType;
    
    m_freq = 220;
    m_phase = 0;
    
    allocatePortBuffers();
}


void AGAudioSquareWaveNode::setInputPortValue(int port, float value)
{
    switch(port)
    {
        case 0: m_freq = value; break;
        case 1: m_gain = value; break;
    }
}

void AGAudioSquareWaveNode::getInputPortValue(int port, float &value) const
{
    switch(port)
    {
        case 0: value = m_freq; break;
        case 1: value = m_gain; break;
    }
}

void AGAudioSquareWaveNode::renderAudio(float *input, float *output, int nFrames)
{
    pullInputPorts(nFrames);
    
    for(int i = 0; i < nFrames; i++)
    {
        output[i] += (m_phase < 0.5 ? 1 : -1)  * (m_gain + m_inputPortBuffer[1][i]);
        
        m_phase += (m_freq + m_inputPortBuffer[0][i])/sampleRate();
        while(m_phase >= 1.0) m_phase -= 1.0;
    }
}


void AGAudioSquareWaveNode::renderIcon()
{
    initialize();
    
    // render icon
    glBindVertexArrayOES(s_audioNodeInfo->iconVertexArray);
    
    glLineWidth(2.0);
    glDrawArrays(s_audioNodeInfo->iconGeoType, 0, s_audioNodeInfo->iconGeoSize);
    
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

AGAudioNode *AGAudioSquareWaveNode::create(const GLvertex3f &pos)
{
    return new AGAudioSquareWaveNode(pos);
}


//------------------------------------------------------------------------------
// ### AGAudioSawtoothWaveNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioSawtoothWaveNode

void AGAudioSawtoothWaveNode::initialize()
{
    initializeAudioNode();
    
    if(s_audioNodeInfo == NULL)
    {
        s_audioNodeInfo = new AGAudioNodeInfo;
        
        // generate geometry
        s_audioNodeInfo->iconGeoSize = 4;
        GLvertex3f * iconGeo = new GLvertex3f[s_audioNodeInfo->iconGeoSize];
        s_audioNodeInfo->iconGeoType = GL_LINE_STRIP;
        float radius_x = 0.005;
        float radius_y = radius_x * 0.66;
        
        // sawtooth wave shape
        iconGeo[0] = GLvertex3f(-radius_x, 0, 0);
        iconGeo[1] = GLvertex3f(-radius_x, radius_y, 0);
        iconGeo[2] = GLvertex3f(radius_x, -radius_y, 0);
        iconGeo[3] = GLvertex3f(radius_x, 0, 0);
        
        genVertexArrayAndBuffer(s_audioNodeInfo->iconGeoSize, iconGeo,
                                s_audioNodeInfo->iconVertexArray, s_audioNodeInfo->iconVertexBuffer);
        
        delete[] iconGeo;
        iconGeo = NULL;
        
        s_audioNodeInfo->portInfo.push_back({ "freq", true, true });
        s_audioNodeInfo->portInfo.push_back({ "gain", true, true });
    }
}

AGAudioSawtoothWaveNode::AGAudioSawtoothWaveNode(GLvertex3f pos) : AGAudioNode(pos)
{
    initialize();
    
    m_inputPortInfo = &s_audioNodeInfo->portInfo[0];
    
    m_iconVertexArray = s_audioNodeInfo->iconVertexArray;
    m_iconGeoSize = s_audioNodeInfo->iconGeoSize;
    m_iconGeoType = s_audioNodeInfo->iconGeoType;
    
    m_freq = 220;
    m_phase = 0;
    
    allocatePortBuffers();
}


void AGAudioSawtoothWaveNode::setInputPortValue(int port, float value)
{
    switch(port)
    {
        case 0: m_freq = value; break;
        case 1: m_gain = value; break;
    }
}

void AGAudioSawtoothWaveNode::getInputPortValue(int port, float &value) const
{
    switch(port)
    {
        case 0: value = m_freq; break;
        case 1: value = m_gain; break;
    }
}

void AGAudioSawtoothWaveNode::renderAudio(float *input, float *output, int nFrames)
{
    pullInputPorts(nFrames);
    
    for(int i = 0; i < nFrames; i++)
    {
        output[i] += ((1-m_phase)*2-1)  * (m_gain + m_inputPortBuffer[1][i]);
        
        m_phase += (m_freq + m_inputPortBuffer[0][i])/sampleRate();
        while(m_phase >= 1.0) m_phase -= 1.0;
    }
}


void AGAudioSawtoothWaveNode::renderIcon()
{
    initialize();
    
    // render icon
    glBindVertexArrayOES(s_audioNodeInfo->iconVertexArray);
    
    glLineWidth(2.0);
    glDrawArrays(s_audioNodeInfo->iconGeoType, 0, s_audioNodeInfo->iconGeoSize);
    
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

AGAudioNode *AGAudioSawtoothWaveNode::create(const GLvertex3f &pos)
{
    return new AGAudioSawtoothWaveNode(pos);
}


//------------------------------------------------------------------------------
// ### AGAudioTriangleWaveNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioTriangleWaveNode

void AGAudioTriangleWaveNode::initialize()
{
    initializeAudioNode();
    
    if(s_audioNodeInfo == NULL)
    {
        s_audioNodeInfo = new AGAudioNodeInfo;
        
        // generate geometry
        s_audioNodeInfo->iconGeoSize = 4;
        GLvertex3f * iconGeo = new GLvertex3f[s_audioNodeInfo->iconGeoSize];
        s_audioNodeInfo->iconGeoType = GL_LINE_STRIP;
        float radius_x = 0.005;
        float radius_y = radius_x * 0.66;
        
        // sawtooth wave shape
        iconGeo[0] = GLvertex3f(-radius_x, 0, 0);
        iconGeo[1] = GLvertex3f(-radius_x*0.5, radius_y, 0);
        iconGeo[2] = GLvertex3f(radius_x*0.5, -radius_y, 0);
        iconGeo[3] = GLvertex3f(radius_x, 0, 0);
        
        genVertexArrayAndBuffer(s_audioNodeInfo->iconGeoSize, iconGeo,
                                s_audioNodeInfo->iconVertexArray,
                                s_audioNodeInfo->iconVertexBuffer);
        
        delete[] iconGeo;
        iconGeo = NULL;
        
        s_audioNodeInfo->portInfo.push_back({ "freq", true, true });
        s_audioNodeInfo->portInfo.push_back({ "gain", true, true });
    }
}

AGAudioTriangleWaveNode::AGAudioTriangleWaveNode(GLvertex3f pos) : AGAudioNode(pos)
{
    initialize();
    
    m_inputPortInfo = &s_audioNodeInfo->portInfo[0];
    
    m_iconVertexArray = s_audioNodeInfo->iconVertexArray;
    m_iconGeoSize = s_audioNodeInfo->iconGeoSize;
    m_iconGeoType = s_audioNodeInfo->iconGeoType;
    
    m_freq = 220;
    m_phase = 0;
    
    allocatePortBuffers();
}


void AGAudioTriangleWaveNode::setInputPortValue(int port, float value)
{
    switch(port)
    {
        case 0: m_freq = value; break;
        case 1: m_gain = value; break;
    }
}

void AGAudioTriangleWaveNode::getInputPortValue(int port, float &value) const
{
    switch(port)
    {
        case 0: value = m_freq; break;
        case 1: value = m_gain; break;
    }
}

void AGAudioTriangleWaveNode::renderAudio(float *input, float *output, int nFrames)
{
    pullInputPorts(nFrames);
    
    for(int i = 0; i < nFrames; i++)
    {
        if(m_phase < 0.5)
            output[i] += ((1-m_phase*2)*2-1) * (m_gain + m_inputPortBuffer[1][i]);
        else
            output[i] += ((m_phase-0.5)*4-1) * (m_gain + m_inputPortBuffer[1][i]);

        m_phase += (m_freq + m_inputPortBuffer[0][i])/sampleRate();
        while(m_phase >= 1.0) m_phase -= 1.0;
    }
}


void AGAudioTriangleWaveNode::renderIcon()
{
    initialize();
    
    // render icon
    glBindVertexArrayOES(s_audioNodeInfo->iconVertexArray);
    
    glLineWidth(2.0);
    glDrawArrays(s_audioNodeInfo->iconGeoType, 0, s_audioNodeInfo->iconGeoSize);
    
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}


AGAudioNode *AGAudioTriangleWaveNode::create(const GLvertex3f &pos)
{
    return new AGAudioTriangleWaveNode(pos);
}


//------------------------------------------------------------------------------
// ### AGAudioADSRNode ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioADSRNode

void AGAudioADSRNode::initialize()
{
    initializeAudioNode();
    
    if(s_audioNodeInfo == NULL)
    {
        s_audioNodeInfo = new AGAudioNodeInfo;
        
        // generate geometry
        s_audioNodeInfo->iconGeoSize = 5;
        GLvertex3f * iconGeo = new GLvertex3f[s_audioNodeInfo->iconGeoSize];
        s_audioNodeInfo->iconGeoType = GL_LINE_STRIP;
        float radius_x = 0.005;
        float radius_y = radius_x * 0.66;
        
        // ADSR shape
        iconGeo[0] = GLvertex3f(-radius_x, -radius_y, 0);
        iconGeo[1] = GLvertex3f(-radius_x*0.75, radius_y, 0);
        iconGeo[2] = GLvertex3f(-radius_x*0.25, 0, 0);
        iconGeo[3] = GLvertex3f(radius_x*0.66, 0, 0);
        iconGeo[4] = GLvertex3f(radius_x, -radius_y, 0);
        
        genVertexArrayAndBuffer(s_audioNodeInfo->iconGeoSize, iconGeo,
                                s_audioNodeInfo->iconVertexArray,
                                s_audioNodeInfo->iconVertexBuffer);
        
        delete[] iconGeo;
        iconGeo = NULL;
        
        s_audioNodeInfo->portInfo.push_back({ "input", true, false });
        s_audioNodeInfo->portInfo.push_back({ "gain", true, true });
        s_audioNodeInfo->portInfo.push_back({ "trigger", true, false });
        s_audioNodeInfo->portInfo.push_back({ "attack", true, true });
        s_audioNodeInfo->portInfo.push_back({ "decay", true, true });
        s_audioNodeInfo->portInfo.push_back({ "sustain", true, true });
        s_audioNodeInfo->portInfo.push_back({ "release", true, true });
    }
}



AGAudioADSRNode::AGAudioADSRNode(GLvertex3f pos) : AGAudioNode(pos)
{
    initialize();
    
    m_inputPortInfo = &s_audioNodeInfo->portInfo[0];
    
    m_iconVertexArray = s_audioNodeInfo->iconVertexArray;
    m_iconGeoSize = s_audioNodeInfo->iconGeoSize;
    m_iconGeoType = s_audioNodeInfo->iconGeoType;
    
    allocatePortBuffers();
}


void AGAudioADSRNode::setInputPortValue(int port, float value)
{
    switch(port)
    {
        case 2:
            break;
        case 3:
            m_attack = value/1000.0f;
            break;
        case 4:
            m_decay = value/1000.0f;
            break;
        case 5:
            m_sustain = value/1000.0f;
            break;
        case 6:
            m_release = value/1000.0f;
            break;
    }
}

void AGAudioADSRNode::getInputPortValue(int port, float &value) const
{
    switch(port)
    {
    }
}

void AGAudioADSRNode::renderAudio(float *input, float *output, int nFrames)
{
    pullInputPorts(nFrames);
    
    for(int i = 0; i < nFrames; i++)
    {
        output[i] += m_inputPortBuffer[0][i];
        
        m_inputPortBuffer[0][i] = 0;
    }
}


void AGAudioADSRNode::renderIcon()
{
    initialize();
    
    // render icon
    glBindVertexArrayOES(s_audioNodeInfo->iconVertexArray);
    
    glLineWidth(2.0);
    glDrawArrays(s_audioNodeInfo->iconGeoType, 0, s_audioNodeInfo->iconGeoSize);
    
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}


AGAudioNode *AGAudioADSRNode::create(const GLvertex3f &pos)
{
    return new AGAudioADSRNode(pos);
}



//------------------------------------------------------------------------------
// ### AGAudioNodeManager ###
//------------------------------------------------------------------------------
#pragma mark - AGAudioNodeManager

AGAudioNodeManager *AGAudioNodeManager::s_instance = NULL;

const AGAudioNodeManager &AGAudioNodeManager::instance()
{
    if(s_instance == NULL)
    {
        s_instance = new AGAudioNodeManager();
    }
    
    return *s_instance;
}

AGAudioNodeManager::AGAudioNodeManager()
{
    m_audioNodeTypes.push_back(new AudioNodeType("SineWave", AGAudioSineWaveNode::renderIcon, AGAudioSineWaveNode::create));
    m_audioNodeTypes.push_back(new AudioNodeType("SquareWave", AGAudioSquareWaveNode::renderIcon, AGAudioSquareWaveNode::create));
    m_audioNodeTypes.push_back(new AudioNodeType("SawtoothWave", AGAudioSawtoothWaveNode::renderIcon, AGAudioSawtoothWaveNode::create));
    m_audioNodeTypes.push_back(new AudioNodeType("TriangleWave", AGAudioTriangleWaveNode::renderIcon, AGAudioTriangleWaveNode::create));
    m_audioNodeTypes.push_back(new AudioNodeType("ADSR", AGAudioADSRNode::renderIcon, AGAudioADSRNode::create));
}

const std::vector<AGAudioNodeManager::AudioNodeType *> &AGAudioNodeManager::audioNodeTypes() const
{
    return m_audioNodeTypes;
}

void AGAudioNodeManager::renderNodeTypeIcon(AudioNodeType *type) const
{
    type->renderIcon();
}

AGAudioNode * AGAudioNodeManager::createNodeType(AudioNodeType *type, const GLvertex3f &pos) const
{
    return type->createNode(pos);
}


