//
//  AGUserInterface.h
//  Auragraph
//
//  Created by Spencer Salazar on 8/14/13.
//  Copyright (c) 2013 Spencer Salazar. All rights reserved.
//

#ifndef __Auragraph__AGUserInterface__
#define __Auragraph__AGUserInterface__

#import <GLKit/GLKit.h>
#import "Geometry.h"
#import "Animation.h"
#import "AGRenderObject.h"

#include <string>


/*------------------------------------------------------------------------------
 - AGUIObject -
 Artifact of previous system design - replaced by AGInteractiveObject
 -----------------------------------------------------------------------------*/
class AGUIObject : public AGInteractiveObject
{
public:
    virtual ~AGUIObject() { }
    
    virtual void fadeOutAndRemove() { }
};


class AGUIFrame : public AGUIObject
{
public:
    AGUIFrame(const GLvertex2f &bottomLeft, const GLvertex2f &topRight);
    AGUIFrame(const GLvertex2f &bottomLeft, const GLvertex2f &bottomRight, const GLvertex2f &topRight, const GLvertex2f &topLeft);
    
    void update(float t, float dt);
    void render();
    
    void touchDown(const GLvertex3f &t);
    void touchMove(const GLvertex3f &t);
    void touchUp(const GLvertex3f &t);
    
    AGUIObject *hitTest(const GLvertex3f &t);
    
private:
    
    GLvertex2f m_geo[4];
};


/*------------------------------------------------------------------------------
 - AGUIButton -
 Standard button.
 -----------------------------------------------------------------------------*/
class AGUIButton : public AGInteractiveObject
{
public:
    AGUIButton(const std::string &title, const GLvertex3f &pos, const GLvertex3f &size);
    virtual ~AGUIButton();
    
    virtual void update(float t, float dt);
    virtual void render();
    
    virtual void touchDown(const GLvertex3f &t);
    virtual void touchMove(const GLvertex3f &t);
    virtual void touchUp(const GLvertex3f &t);
    
    void setAction(void (^action)());
    bool isPressed();
    void setLatched(bool latched);
    
    virtual bool renderFixed() { return true; }
    
//    enum ActionType
//    {
//        ACTION_ONTOUCHDOWN,
//        ACTION_ONTOUCHUP,
//    };
//    
//    void setActionType(ActionType t) { m_actionType = t; }
//    ActionType getActionType() { return m_actionType; }
    
    enum InteractionType
    {
        INTERACTION_UPDOWN,
        INTERACTION_LATCH,
    };
    
    void setInteractionType(InteractionType t) { m_interactionType = t; }
    InteractionType getInteractionType() { return m_interactionType; }
    
protected:
    
    GLvrectf effectiveBounds();
    
    std::string m_title;
    
    GLvertex3f m_pos, m_size;
    GLvertex3f m_geo[8];
    
    bool m_hit;
    bool m_hitOnTouchDown;
    bool m_latch;
    
//    ActionType m_actionType;
    InteractionType m_interactionType;
    
    void (^m_action)();
};


/*------------------------------------------------------------------------------
 - AGTextButton -
 Text button - displays as just text, and showing a border when pressed.
 -----------------------------------------------------------------------------*/
class AGUITextButton : public AGUIButton
{
public:
    AGUITextButton(const std::string &title, const GLvertex3f &pos, const GLvertex3f &size) :
    AGUIButton(title, pos, size) { }
    
    virtual void render();
};


/*------------------------------------------------------------------------------
 - AGUIIconButton -
 Button that allows display of customized icon.
 -----------------------------------------------------------------------------*/
class AGUIIconButton : public AGUIButton
{
public:
    AGUIIconButton(const GLvertex3f &pos, const GLvertex2f &size, const AGRenderInfoV &iconRenderInfo);
    
    virtual void update(float t, float dt);
    virtual void render();
    
    virtual GLvertex3f position() { GLvertex3f parentPos = GLvertex3f(0, 0, 0); if(parent()) parentPos = parent()->position(); return parentPos+m_pos; }
    virtual GLvertex2f size() { return m_size.xy(); }
    virtual GLvrectf effectiveBounds() { return GLvrectf(position()-size()*0.5, position()+size()*0.5); }
    
    enum IconMode
    {
        ICONMODE_SQUARE,
        ICONMODE_CIRCLE,
    };
    
    void setIconMode(IconMode m);
    IconMode getIconMode();
    
private:
    GLvertex3f *m_boxGeo;
    AGRenderInfoV m_boxInfo;
    AGRenderInfoV m_iconInfo;
    
    IconMode m_iconMode;
};



/*------------------------------------------------------------------------------
 - AGUIButtonGroup -
 Button group for mode selector-type buttons.
 -----------------------------------------------------------------------------*/
class AGUIButtonGroup : public AGInteractiveObject
{
public:
    AGUIButtonGroup();
    ~AGUIButtonGroup();
    
    void addButton(AGUIButton *button, void (^action)(), bool isDefault);
    
private:
    std::list<AGUIButton *> m_buttons;
};



/*------------------------------------------------------------------------------
 - AGUITrash -
 Node deletion interface.
 -----------------------------------------------------------------------------*/
class AGUITrash : public AGUIObject
{
public:
    static AGUITrash &instance();
    
    virtual void update(float t, float dt);
    virtual void render();
    
    virtual void touchDown(const GLvertex3f &t);
    virtual void touchMove(const GLvertex3f &t);
    virtual void touchUp(const GLvertex3f &t);
    
    void activate();
    void deactivate();
    
    virtual AGUIObject *hitTest(const GLvertex3f &t);
    
    virtual void setPosition(const GLvertex3f &pos) { m_position = pos; }
    
    virtual bool renderFixed() { return true; }
    
private:
    AGUITrash();
    ~AGUITrash();
    
    bool m_active;
    slewf m_scale;
    
    float m_radius;
    GLvertex3f m_position;
    GLuint m_tex;
    GLvertex3f m_geo[4];
    GLvertex2f m_uv[4];
};


/*------------------------------------------------------------------------------
 - AGUITrace -
 -----------------------------------------------------------------------------*/
class AGUITrace : public AGInteractiveObject
{
public:
    AGUITrace();
    
    virtual void update(float t, float dt);
    virtual void render();
    
    virtual void touchDown(const GLvertex3f &t);
    virtual void touchMove(const GLvertex3f &t);
    virtual void touchUp(const GLvertex3f &t);
    
//    AGHandwritingRecognizerFigure recognizeNumeral();
    
private:
    
};

#endif /* defined(__Auragraph__AGUserInterface__) */
