//
//  AGNode.h
//  Auragraph
//
//  Created by Spencer Salazar on 8/12/13.
//  Copyright (c) 2013 Spencer Salazar. All rights reserved.
//

#ifndef __Auragraph__AGNode__
#define __Auragraph__AGNode__


#import "Geometry.h"
#import "ES2Render.h"
#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>
#import "ShaderHelper.h"
#import <list>
#import <string>
#import <vector>


class AGNode;

enum AGRate
{
    RATE_CONTROL,
    RATE_AUDIO,
};


class AGConnection
{
public:
    
    AGConnection(AGNode * src, AGNode * dst, int dstPort);
    ~AGConnection();
    
    virtual void update(float t, float dt);
    virtual void render();
    
    AGNode * src() const { return m_src; }
    AGNode * dst() const { return m_dst; }
    int dstPort() const { return m_dstPort; }
    
    AGRate rate() { return m_rate; }
    
private:
    
    static bool s_init;
    static GLuint s_program;
    static GLint s_uniformMVPMatrix;
    static GLint s_uniformNormalMatrix;
    static GLint s_uniformColor2;
    
    GLvertex3f *m_geo;
    GLcolor4f m_color;
    GLuint m_geoSize;
    
    AGNode * const m_src;
    AGNode * const m_dst;
    const int m_dstPort;
    
    GLvertex3f m_outTerminal;
    GLvertex3f m_inTerminal;
    
    const AGRate m_rate;
    
    static void initalize();
    
    void updatePath();
};


struct AGPortInfo
{
    std::string name;
    bool canConnect; // can create connection btw this port and another port
    bool canEdit; // should this port appear in the node's editor window
    
    // TODO: min, max, units label, etc.
};


class AGNode
{
public:
    
    static void initalizeNode()
    {
        if(!s_initNode)
        {
            s_initNode = true;
            
            s_program = [ShaderHelper createProgram:@"Shader"
                                     withAttributes:SHADERHELPER_ATTR_POSITION | SHADERHELPER_ATTR_NORMAL | SHADERHELPER_ATTR_COLOR];
            s_uniformMVPMatrix = glGetUniformLocation(s_program, "modelViewProjectionMatrix");
            s_uniformNormalMatrix = glGetUniformLocation(s_program, "normalMatrix");
            s_uniformColor2 = glGetUniformLocation(s_program, "color2");
        }
    }
    
    static void setProjectionMatrix(const GLKMatrix4 &proj)
    {
        s_projectionMatrix = proj;
    }
    
    static GLKMatrix4 projectionMatrix() { return s_projectionMatrix; }
    
    static void setGlobalModelViewMatrix(const GLKMatrix4 &modelview)
    {
        s_modelViewMatrix = modelview;
    }
    
    static GLKMatrix4 globalModelViewMatrix() { return s_modelViewMatrix; }
    
    static void connect(AGConnection * connection)
    {
        connection->src()->m_outbound.push_back(connection);
        connection->dst()->m_inbound.push_back(connection);
    }
    
    
    AGNode(GLvertex3f pos = GLvertex3f()) :
    m_pos(pos)
    { }
    
    virtual void update(float t, float dt) = 0;
    virtual void render() = 0;
    
    enum HitTestResult
    {
        HIT_NONE = 0,
        HIT_INPUT_NODE,
        HIT_OUTPUT_NODE,
        HIT_MAIN_NODE,
    };
    
    virtual HitTestResult hit(const GLvertex2f &hit) = 0;
    virtual void unhit() = 0;
    
    void setPosition(const GLvertex3f &pos) { m_pos = pos; }
    const GLvertex3f &position() const { return m_pos; }
    
    virtual int numOutputPorts() const { return 0; }
    virtual int numInputPorts() const { return 0; }
    virtual const AGPortInfo &inputPortInfo(int port) { return m_inputPortInfo[port]; }
    
    virtual GLvertex3f positionForInboundConnection(AGConnection * connection) const { return GLvertex3f(); }
    virtual GLvertex3f positionForOutboundConnection(AGConnection * connection) const { return GLvertex3f(); }
    
    // 1: positive activation; 0: deactivation; -1: negative activation
    virtual void activateInputPort(int type) { }
    virtual void activateOutputPort(int type) { }
    
    virtual AGRate rate() { return RATE_CONTROL; }
    
private:
    
    static bool s_initNode;
    
    static GLKMatrix4 s_projectionMatrix;
    static GLKMatrix4 s_modelViewMatrix;
    
protected:
    static GLuint s_program;
    static GLint s_uniformMVPMatrix;
    static GLint s_uniformNormalMatrix;
    static GLint s_uniformColor2;
    
    const static float s_sizeFactor;
    
    std::list<AGConnection *> m_inbound;
    std::list<AGConnection *> m_outbound;
    AGPortInfo * m_inputPortInfo;
    
    GLvertex3f m_pos;
    GLKMatrix4 m_modelViewProjectionMatrix;
    GLKMatrix3 m_normalMatrix;
};


class AGControlNode : public AGNode
{
public:
    
    static void initializeControlNode();
    
    AGControlNode(GLvertex3f pos = GLvertex3f());
    
    virtual void update(float t, float dt);
    virtual void render();
    virtual HitTestResult hit(const GLvertex2f &hit);
    virtual void unhit();

private:
    
    static bool s_init;
    static GLuint s_vertexArray;
    static GLuint s_vertexBuffer;
    
    static GLvncprimf *s_geo;
    static GLuint s_geoSize;
    
};



class AGInputNode : public AGNode
{
public:
    
    static void initializeInputNode();
    
    AGInputNode(GLvertex3f pos = GLvertex3f());
    
    virtual void update(float t, float dt);    
    virtual void render();
    virtual HitTestResult hit(const GLvertex2f &hit);
    virtual void unhit();

private:
    
    static bool s_init;
    static GLuint s_vertexArray;
    static GLuint s_vertexBuffer;
    
    static GLvncprimf *s_geo;
    static GLuint s_geoSize;
};



class AGOutputNode : public AGNode
{
public:
    
    static void initializeOutputNode();
    
    AGOutputNode(GLvertex3f pos = GLvertex3f());
    
    virtual void update(float t, float dt);
    virtual void render();
    virtual HitTestResult hit(const GLvertex2f &hit);
    virtual void unhit();

private:
    
    static bool s_init;
    static GLuint s_vertexArray;
    static GLuint s_vertexBuffer;
    
    static GLvncprimf *s_geo;
    static GLuint s_geoSize;
};



#endif /* defined(__Auragraph__AGNode__) */
