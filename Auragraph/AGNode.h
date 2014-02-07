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
#import "AGUserInterface.h"
#import "Mutex.h"
#import "AGControl.h"

#import <list>
#import <string>
#import <vector>


class AGNode;

enum AGRate
{
    RATE_CONTROL,
    RATE_AUDIO,
};

struct AGPortInfo
{
    std::string name;
    bool canConnect; // can create connection btw this port and another port
    bool canEdit; // should this port appear in the node's editor window
    
    // TODO: min, max, units label, etc.
};

struct AGNodeInfo
{
    AGNodeInfo() : iconGeo(NULL), iconGeoSize(0), iconGeoType(GL_LINE_STRIP) { }
    
    GLvertex3f *iconGeo;
    GLuint iconGeoSize;
    GLuint iconGeoType;
    
    vector<AGPortInfo> portInfo;
};

typedef unsigned long long sampletime;


class AGConnection : public AGUIObject
{
public:
    
    AGConnection(AGNode * src, AGNode * dst, int dstPort);
    ~AGConnection();
    
    virtual void update(float t, float dt);
    virtual void render();
    
    virtual void touchDown(const GLvertex3f &t);
    virtual void touchMove(const GLvertex3f &t);
    virtual void touchUp(const GLvertex3f &t);
    
    virtual AGUIObject *hitTest(const GLvertex3f &t);
    
    AGNode * src() const { return m_src; }
    AGNode * dst() const { return m_dst; }
    int dstPort() const { return m_dstPort; }
    
    AGRate rate() { return m_rate; }
    
private:
    
    static bool s_init;
    static GLuint s_program;
    static GLint s_uniformMVPMatrix;
    static GLint s_uniformNormalMatrix;
    
    GLvertex3f m_geo[3];
    GLcolor4f m_color;
    GLuint m_geoSize;
    
    AGNode * const m_src;
    AGNode * const m_dst;
    const int m_dstPort;
    
    GLvertex3f m_outTerminal;
    GLvertex3f m_inTerminal;
    
    bool m_hit;
    bool m_stretch;
    bool m_break;
    GLvertex3f m_stretchPoint;
    
    const AGRate m_rate;
    
    static void initalize();
    
    void updatePath();
};


class AGNode : public AGUIObject
{
public:
    
    static void initalizeNode();
    
    static void setProjectionMatrix(const GLKMatrix4 &proj) { s_projectionMatrix = proj; }
    static GLKMatrix4 projectionMatrix() { return s_projectionMatrix; }
    static void setGlobalModelViewMatrix(const GLKMatrix4 &modelview) { s_modelViewMatrix = modelview; }
    static GLKMatrix4 globalModelViewMatrix() { return s_modelViewMatrix; }
    
    static void connect(AGConnection * connection);
    static void disconnect(AGConnection * connection);
    
    AGNode(GLvertex3f pos = GLvertex3f()) : m_pos(pos), m_nodeInfo(NULL), m_inputPortInfo(NULL) { }
    virtual ~AGNode();
    
    virtual void update(float t, float dt) = 0;
    virtual void render() = 0;
    
    enum HitTestResult
    {
        HIT_NONE = 0,
        HIT_INPUT_NODE,
        HIT_OUTPUT_NODE,
        HIT_MAIN_NODE,
    };
    
    virtual HitTestResult hit(const GLvertex3f &hit) = 0;
    virtual void unhit() = 0;
    
    void setPosition(const GLvertex3f &pos) { m_pos = pos; }
    const GLvertex3f &position() const { return m_pos; }
    
    virtual void touchDown(const GLvertex3f &t);
    virtual void touchMove(const GLvertex3f &t);
    virtual void touchUp(const GLvertex3f &t);
    
    void lock() { m_mutex.lock(); }
    void unlock() { m_mutex.unlock(); }
    
    // TODO: all of these should be virtual
    /*** Subclassing note: the following public functions should be overridden ***/
    virtual int numOutputPorts() const { return 0; }
    virtual int numInputPorts() const { return 0; }
    virtual const AGPortInfo &inputPortInfo(int port) { return m_inputPortInfo[port]; }
    virtual void setInputPortValue(int port, float value) { }
    virtual void getInputPortValue(int port, float &value) const { }
    
    virtual GLvertex3f positionForInboundConnection(AGConnection * connection) const { return GLvertex3f(); }
    virtual GLvertex3f positionForOutboundConnection(AGConnection * connection) const { return GLvertex3f(); }
    
    // 1: positive activation; 0: deactivation; -1: negative activation
    virtual void activateInputPort(int type) { }
    virtual void activateOutputPort(int type) { }
    virtual void activate(int type) { }
    
    virtual AGRate rate() { return RATE_CONTROL; }
    
private:
    static bool s_initNode;
    
    static GLKMatrix4 s_projectionMatrix;
    static GLKMatrix4 s_modelViewMatrix;
    
    Mutex m_mutex;
    
protected:
    const static float s_sizeFactor;
    
    virtual void addInbound(AGConnection *connection);
    virtual void addOutbound(AGConnection *connection);
    virtual void removeInbound(AGConnection *connection);
    virtual void removeOutbound(AGConnection *connection);
    
    AGNodeInfo *m_nodeInfo;
    
    std::list<AGConnection *> m_inbound;
    std::list<AGConnection *> m_outbound;
    AGPortInfo * m_inputPortInfo;
    
    GLvertex3f m_pos;
    GLKMatrix4 m_modelViewProjectionMatrix;
    GLKMatrix3 m_normalMatrix;
    
    // touch handling stuff
    GLvertex3f m_lastTouch;
};


class AGControlNode : public AGNode
{
public:
    static void initializeControlNode();
    
    AGControlNode(GLvertex3f pos = GLvertex3f());
    virtual ~AGControlNode() { }
    
    virtual void update(float t, float dt);
    virtual void render();
    
    virtual AGUIObject *hitTest(const GLvertex3f &t);
    
    virtual HitTestResult hit(const GLvertex3f &hit);
    virtual void unhit();
    
    // TODO
    virtual GLvertex3f positionForInboundConnection(AGConnection * connection) const { return GLvertex3f(); }
    virtual GLvertex3f positionForOutboundConnection(AGConnection * connection) const { return GLvertex3f(); }
    
    // TODO
    // 1: positive activation; 0: deactivation; -1: negative activation
    virtual void activateInputPort(int type) { }
    virtual void activateOutputPort(int type) { }
    virtual void activate(int type) { }
    
    virtual AGControl *renderControl(sampletime t) = 0;
    
private:
    
    static bool s_init;
    static GLuint s_vertexArray;
    static GLuint s_vertexBuffer;
    static float s_radius;
    
    static GLvncprimf *s_geo;
    static GLuint s_geoSize;
    
protected:
    AGControl *m_control;
    GLvertex3f *m_iconGeo;
    GLuint m_geoSize;
    GLuint m_geoType;
};



class AGControlTimerNode : public AGControlNode
{
public:
    static void initialize();

    AGControlTimerNode(const GLvertex3f &pos);
    
    virtual int numOutputPorts() const { return 1; }
    virtual int numInputPorts() const { return 0; }
    virtual const AGPortInfo &inputPortInfo(int port) { return m_inputPortInfo[port]; }
    virtual void setInputPortValue(int port, float value);
    virtual void getInputPortValue(int port, float &value) const;

    virtual AGControl *renderControl(sampletime t);
    
private:
    static AGNodeInfo *s_nodeInfo;
    
    sampletime m_lastTime;
    sampletime m_lastFire;
    float m_interval;
};



class AGInputNode : public AGNode
{
public:
    
    static void initializeInputNode();
    
    AGInputNode(GLvertex3f pos = GLvertex3f());
    
    virtual void update(float t, float dt);    
    virtual void render();
    
    virtual AGUIObject *hitTest(const GLvertex3f &t);

    virtual HitTestResult hit(const GLvertex3f &hit);
    virtual void unhit();

private:
    
    static bool s_init;
    static GLuint s_vertexArray;
    static GLuint s_vertexBuffer;
    static float s_radius;

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
    
    virtual AGUIObject *hitTest(const GLvertex3f &t);

    virtual HitTestResult hit(const GLvertex3f &hit);
    virtual void unhit();

private:
    
    static bool s_init;
    static GLuint s_vertexArray;
    static GLuint s_vertexBuffer;
    static float s_radius;

    static GLvncprimf *s_geo;
    static GLuint s_geoSize;
};


class AGFreeDraw : public AGUIObject
{
public:
    AGFreeDraw(GLvncprimf *points, int nPoints);
    ~AGFreeDraw();
    
    virtual void update(float t, float dt);
    virtual void render();
    
    virtual void touchDown(const GLvertex3f &t);
    virtual void touchMove(const GLvertex3f &t);
    virtual void touchUp(const GLvertex3f &t);
    
    virtual AGUIObject *hitTest(const GLvertex3f &t);
    
private:
    GLvncprimf *m_points;
    int m_nPoints;
    bool m_touchDown;
    GLvertex3f m_position;
    GLvertex3f m_touchLast;
    
    // debug
    int m_touchPoint0;
};




#endif /* defined(__Auragraph__AGNode__) */
