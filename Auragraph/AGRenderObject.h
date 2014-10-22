//
//  AGRenderObject.h
//  Auragraph
//
//  Created by Spencer Salazar on 10/14/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#ifndef __Auragraph__AGRenderObject__
#define __Auragraph__AGRenderObject__

#import "Geometry.h"
#import "AGGenericShader.h"

#import <list>
using namespace std;

struct AGRenderInfo
{
public:
    virtual void set() = 0;
    
    AGGenericShader *shader;
    GLuint numVertex;
    GLuint geoType;
};

struct AGRenderInfoV : public AGRenderInfo
{
    virtual void set()
    {
        glVertexAttrib4fv(GLKVertexAttribColor, (const float *) &color);
        glVertexAttrib3f(GLKVertexAttribNormal, 0, 0, 1);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLvertex3f), geo);
    }
    
    GLcolor4f color;
    GLvertex3f *geo;
};

struct AGRenderInfoVC : public AGRenderInfo
{
    virtual void set()
    {
        glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(GLvcprimf), &geo->color);
        glVertexAttrib3f(GLKVertexAttribNormal, 0, 0, 1);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLvcprimf), &geo->vertex);
    }
    
    GLvcprimf *geo;
};


struct AGRenderState
{
    GLKMatrix4 projection;
    GLKMatrix4 modelview;
    GLKMatrix3 normal;
};

class AGRenderObject
{
public:
    static void setProjectionMatrix(const GLKMatrix4 &proj) { s_projectionMatrix = proj; }
    static GLKMatrix4 projectionMatrix() { return s_projectionMatrix; }
    static void setGlobalModelViewMatrix(const GLKMatrix4 &modelview) { s_modelViewMatrix = modelview; }
    static GLKMatrix4 globalModelViewMatrix() { return s_modelViewMatrix; }
    
    AGRenderObject();
    virtual ~AGRenderObject();
    
    virtual void update(float t, float dt);
    virtual void render();
    
    list<AGRenderInfo *> m_renderList;
    AGRenderState m_renderState;
    
protected:
    static GLKMatrix4 s_projectionMatrix;
    static GLKMatrix4 s_modelViewMatrix;
    
    void renderPrimitives();
};


struct AGTouchInfo
{
    GLvertex3f position;
    CGPoint screenPosition;
    int touchId;
};


class AGInteractiveObject : public AGRenderObject
{
public:
    AGInteractiveObject();
    virtual ~AGInteractiveObject();
    
    virtual void touchDown(const GLvertex3f &t);
    virtual void touchMove(const GLvertex3f &t);
    virtual void touchUp(const GLvertex3f &t);
    
    // new version
    virtual void touchDown(const AGTouchInfo &t);
    virtual void touchMove(const AGTouchInfo &t);
    virtual void touchUp(const AGTouchInfo &t);
    
    virtual AGInteractiveObject *hitTest(const GLvertex3f &t);
    
    void addChild(AGInteractiveObject *child);
    void removeChild(AGInteractiveObject *child);
    
protected:
    virtual GLvrectf effectiveBounds() { return GLvrectf(); }
    
    list<AGInteractiveObject *> m_children;
};


#endif /* defined(__Auragraph__AGRenderObject__) */


