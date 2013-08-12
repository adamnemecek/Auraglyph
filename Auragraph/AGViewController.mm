//
//  AGViewController.m
//  Auragraph
//
//  Created by Spencer Salazar on 8/2/13.
//  Copyright (c) 2013 Spencer Salazar. All rights reserved.
//

#import "AGViewController.h"
#import "Geometry.h"
#import "ShaderHelper.h"
#import "hsv.h"
#import "UIKitGL.h"
#import "AGHandwritingRecognizer.h"
#import "AGNode.h"

#import <list>


// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};


struct DrawPoint
{
    GLvncprimf geo; // GL geometry
};

const int nDrawline = 1024;
int nDrawlineUsed = 0;
DrawPoint drawline[nDrawline];


@interface AGViewController ()
{
    GLuint _program;
    
    GLKMatrix4 _modelView;
    GLKMatrix4 _projection;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    float _t;
    float _osc;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    AGHandwritingRecognizer *_hwRecognizer;
    LTKTrace _currentTrace;
    GLvertex3f _currentTraceSum;
    
    std::list<AGNode *> _nodes;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation AGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    
    _hwRecognizer = [AGHandwritingRecognizer new];
    _currentTrace = LTKTrace();
    
    _nodes = std::list<AGNode *>();
    _t = 0;
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    _program = [ShaderHelper createProgramForVertexShader:[[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"]
                                           fragmentShader:[[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"]];
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(drawline), drawline, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(DrawPoint), BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(DrawPoint), BUFFER_OFFSET(sizeof(GLvertex3f)));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(DrawPoint), BUFFER_OFFSET(2*sizeof(GLvertex3f)));
    
    glBindVertexArrayOES(0);
    
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    _modelView = modelViewMatrix;
    _projection = projectionMatrix;
    
    AGNode::setProjectionMatrix(projectionMatrix);
    AGNode::setGlobalModelViewMatrix(modelViewMatrix);
    
    _osc += self.timeSinceLastUpdate * 1.0f;
    _t += self.timeSinceLastUpdate;
    
    for(std::list<AGNode *>::iterator i = _nodes.begin(); i != _nodes.end(); i++)
    {
        (*i)->update(_t, self.timeSinceLastUpdate);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(drawline), drawline, GL_DYNAMIC_DRAW);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    for(std::list<AGNode *>::iterator i = _nodes.begin(); i != _nodes.end(); i++)
    {
        (*i)->render();
    }
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glBindVertexArrayOES(_vertexArray);
    
    glLineWidth(4.0f);
    if(nDrawlineUsed == 1)
        glDrawArrays(GL_POINTS, 0, nDrawlineUsed);
    else
        glDrawArrays(GL_LINE_STRIP, 0, nDrawlineUsed);
}


#pragma Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:self.view];
    
    int viewport[] = { (int)self.view.frame.origin.x, (int)self.view.frame.origin.y,
        (int)self.view.frame.size.width, (int)self.view.frame.size.height };
    GLKVector3 vec = GLKMathUnproject(GLKVector3Make(p.x, p.y, 0.01),
                                      _modelView, _projection, viewport, NULL);
    
    drawline[0].geo.vertex = GLvertex3f(vec.x, -vec.y, vec.z);
    drawline[0].geo.color = GLcolor4f(1, 1, 1, 1);
    drawline[0].geo.normal = GLvertex3f(0, 0, 1);
    
    // reset trace
    _currentTrace = LTKTrace();

    floatVector point;
    point.push_back(p.x);
    point.push_back(p.y);
    _currentTrace.addPoint(point);
    
    _currentTraceSum = GLvertex3f(p.x, p.y, 0);
    
    nDrawlineUsed = 1;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:self.view];
    
    int viewport[] = { (int)self.view.frame.origin.x, (int)self.view.frame.origin.y,
        (int)self.view.frame.size.width, (int)self.view.frame.size.height };
    GLKVector3 vec = GLKMathUnproject(GLKVector3Make(p.x, p.y, 0.01),
                                      _modelView, _projection, viewport, NULL);
    
    drawline[nDrawlineUsed].geo.vertex = GLvertex3f(vec.x, -vec.y, vec.z);
    drawline[nDrawlineUsed].geo.color = GLcolor4f(0.75, 0.75, 0.75, 1);
    drawline[nDrawlineUsed].geo.normal = GLvertex3f(0, 0, 1);
    
    _currentTraceSum = _currentTraceSum + GLvertex3f(p.x, p.y, 0);
    
    floatVector point;
    point.push_back(p.x);
    point.push_back(p.y);
    _currentTrace.addPoint(point);
    
    nDrawlineUsed++;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // analysis
    
    AGHandwritingRecognizerFigure figure = [_hwRecognizer recognizeShapeInView:self.view
                                                                         trace:_currentTrace];
    
    NSLog(@"figure: %i", figure);
    
    int viewport[] = { (int)self.view.frame.origin.x, (int)self.view.frame.origin.y,
        (int)self.view.frame.size.width, (int)self.view.frame.size.height };
    GLvertex3f centroid = _currentTraceSum/nDrawlineUsed;
    GLKVector3 centroidMVP = GLKMathUnproject(GLKVector3Make(centroid.x, centroid.y, 0.01),
                                              _modelView, _projection, viewport, NULL);
    
    if(figure == AG_FIGURE_CIRCLE)
    {
        AGAudioNode * node = new AGAudioNode(GLvertex3f(centroidMVP.x, -centroidMVP.y, centroidMVP.z));
        _nodes.push_back(node);
        nDrawlineUsed = 0;
    }
    else if(figure == AG_FIGURE_SQUARE)
    {
        AGControlNode * node = new AGControlNode(GLvertex3f(centroidMVP.x, -centroidMVP.y, centroidMVP.z));
        _nodes.push_back(node);
        nDrawlineUsed = 0;
    }
    else if(figure == AG_FIGURE_TRIANGLE_DOWN)
    {
        AGInputNode * node = new AGInputNode(GLvertex3f(centroidMVP.x, -centroidMVP.y, centroidMVP.z));
        _nodes.push_back(node);
        nDrawlineUsed = 0;
    }
    else if(figure == AG_FIGURE_TRIANGLE_UP)
    {
        AGOutputNode * node = new AGOutputNode(GLvertex3f(centroidMVP.x, -centroidMVP.y, centroidMVP.z));
        _nodes.push_back(node);
        nDrawlineUsed = 0;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}



@end
