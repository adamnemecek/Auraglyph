//
//  AGAboutBox.mm
//  Auragraph
//
//  Created by Spencer Salazar on 11/5/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#include "AGAboutBox.h"
#include "AGViewController.h"
#include "AGStyle.h"
#include "AGGenericShader.h"

static const float AGABOUTBOX_RADIUS = 0.066*AGStyle::oldGlobalScale;

//------------------------------------------------------------------------------
// ### AGAboutBox ###
//------------------------------------------------------------------------------
#pragma mark - AGAboutBox

AGAboutBox::AGAboutBox(const GLvertex3f &pos) :
m_pos(pos),
m_done(false)
{
    m_geoSize = 4;
    
    m_radius = AGABOUTBOX_RADIUS;
    
    // stroke GL_LINE_STRIP + fill GL_TRIANGLE_FAN
    m_geo[0] = GLvertex3f(-m_radius, m_radius, 0);
    m_geo[1] = GLvertex3f(-m_radius, -m_radius, 0);
    m_geo[2] = GLvertex3f(m_radius, -m_radius, 0);
    m_geo[3] = GLvertex3f(m_radius, m_radius, 0);
    
    m_lines.push_back("an infinite modular");
    m_lines.push_back("musical sketchpad");
    m_lines.push_back("");
    m_lines.push_back("created and designed");
    m_lines.push_back("by Spencer Salazar");
    m_lines.push_back("https://auragly.ph/");
    m_lines.push_back("");
    m_lines.push_back("Auraglyph Team");
    m_lines.push_back("Spencer Salazar");
    m_lines.push_back("Andrew Piepenbrink, April Gerloff");
    m_lines.push_back("");
    m_lines.push_back("Copyright 2017");
    m_lines.push_back("All rights reserved");
}

AGAboutBox::~AGAboutBox()
{
}

void AGAboutBox::update(float t, float dt)
{
    AGInteractiveObject::update(t, dt);
    m_squeeze.update(t, dt);
    
    m_modelView = AGNode::fixedModelViewMatrix();
    m_projection = AGNode::projectionMatrix();
    
    m_modelView = GLKMatrix4Translate(m_modelView, m_pos.x, m_pos.y, m_pos.z);
    m_modelView = GLKMatrix4Multiply(m_modelView, m_squeeze.matrix());
}

void AGAboutBox::render()
{
    AGInteractiveObject::render();
    
    TexFont *text = AGStyle::standardFont64();
    
    glDisable(GL_TEXTURE_2D);
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    /* draw bounding box */
    
    AGGenericShader &shader = AGGenericShader::instance();
    
    shader.useProgram();
    
    shader.setProjectionMatrix(m_projection);
    shader.setModelViewMatrix(m_modelView);
    shader.setNormalMatrix(GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(m_modelView), NULL));
    
    glDisableVertexAttribArray(AGVertexAttribColor);
    glDisableVertexAttribArray(AGVertexAttribNormal);
    glDisableVertexAttribArray(AGVertexAttribTexCoord0);
    
    glVertexAttribPointer(AGVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLvertex3f), m_geo);
    glEnableVertexAttribArray(AGVertexAttribPosition);
    glVertexAttrib3f(AGVertexAttribNormal, 0, 0, 1);
    
    // stroke
    glVertexAttrib4fv(AGVertexAttribColor, (const float *) &GLcolor4f::white);
    glLineWidth(4.0f);
    glDrawArrays(GL_LINE_LOOP, 0, m_geoSize);
    
    // fill
    GLcolor4f blackA = GLcolor4f(0, 0, 0, 0.75);
    glVertexAttrib4fv(AGVertexAttribColor, (const float *) &blackA);
    glDrawArrays(GL_TRIANGLE_FAN, 0, m_geoSize);
    
    float titleScale = 2;
    float titleHeight = m_radius-text->height()*titleScale*1.5;
    string title = "AURAGLYPH";
    GLKMatrix4 titleMV = GLKMatrix4Translate(m_modelView, -text->width(title)*titleScale/2, titleHeight, 0);
    titleMV = GLKMatrix4Scale(titleMV, titleScale, titleScale, titleScale);
    text->render(title, GLcolor4f::white, titleMV, m_projection);
    
    float lineHeight = text->height()*1.4;
    GLKMatrix4 lineMV = GLKMatrix4Translate(m_modelView, 0, titleHeight - lineHeight, 0);
    
    for(int i = 0; i < m_lines.size(); i++)
    {
        if(m_lines[i].length())
        {
            GLKMatrix4 textMV = GLKMatrix4Translate(lineMV, -text->width(m_lines[i])/2, 0, 0);
            text->render(m_lines[i], GLcolor4f::white, textMV, m_projection);
        }
        
        lineMV = GLKMatrix4Translate(lineMV, 0, -lineHeight, 0);
    }
}

AGInteractiveObject *AGAboutBox::hitTest(const GLvertex3f &t)
{
    AGInteractiveObject *hit = AGInteractiveObject::hitTest(t);
    if(hit != this) { removeFromTopLevel(); } //m_closeAction();
    return this;
}

void AGAboutBox::renderOut()
{
    m_squeeze.close();
}

bool AGAboutBox::finishedRenderingOut()
{
    return m_squeeze.finishedClosing();
}

GLvrectf AGAboutBox::effectiveBounds()
{
    return GLvrectf(m_pos + GLvertex3f(-m_radius, -m_radius, 0), m_pos + GLvertex3f(m_radius, m_radius, 0));
}


