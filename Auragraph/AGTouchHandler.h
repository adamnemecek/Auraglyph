//
//  AGTouchHandler.h
//  Auragraph
//
//  Created by Spencer Salazar on 2/2/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Geometry.h"
#import "AGHandwritingRecognizer.h"
#import "AGNode.h"
#import "AGUserInterface.h"


@class AGViewController;

@interface AGTouchHandler : UIResponder
{
    AGViewController *_viewController;
    AGTouchHandler * _nextHandler;
}

- (id)initWithViewController:(AGViewController *)viewController;
- (AGTouchHandler *)nextHandler;

- (void)update:(float)t dt:(float)dt;
- (void)render;

@end

@interface AGDrawNodeTouchHandler : AGTouchHandler
{
    LTKTrace _currentTrace;
    GLvertex3f _currentTraceSum;
}

@end

@interface AGMoveNodeTouchHandler : AGTouchHandler
{
    GLvertex3f _anchorOffset;
    AGNode * _moveNode;
    
    GLvertex2f _firstPoint;
    float _maxTouchTravel;
}

- (id)initWithViewController:(AGViewController *)viewController node:(AGNode *)node;

@end

@interface AGConnectTouchHandler : AGTouchHandler
{
    AGNode * _connectInput;
    AGNode * _connectOutput;
    AGNode * _currentHit;
}

@end

@interface AGSelectNodeTouchHandler : AGTouchHandler
{
    AGUINodeSelector * _nodeSelector;
}

- (id)initWithViewController:(AGViewController *)viewController position:(GLvertex3f)pos;

@end

@interface AGEditTouchHandler : AGTouchHandler
{
    AGUINodeEditor * _nodeEditor;
}

- (id)initWithViewController:(AGViewController *)viewController node:(AGNode *)node;

@end

