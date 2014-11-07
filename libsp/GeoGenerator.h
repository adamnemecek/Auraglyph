//
//  GeoGenerator.h
//  Auragraph
//
//  Created by Spencer Salazar on 10/21/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#ifndef Auragraph_GeoGenerator_h
#define Auragraph_GeoGenerator_h

#include "Geometry.h"
#include <math.h>


namespace GeoGen
{
    /* makeCircle()
     - Generate vertices for circle centered at (0,0,0) and with specified radius
     - points array must have sufficient space for numPoints GLvertex3f's
     - Draw as stroke with GL_LINE_LOOP (skip the first vertex)
     or fill with GL_TRIANGLE_FAN
     */
    void makeCircle(GLvertex3f *points, int numPoints, float radius);
    
    /* circle64()
     - Return 64 vertex circle, created a la makeCircle() above
     - radius = 1
     */
    GLvertex3f *circle64();
    
    /* makeRect()
     - Generate vertices for rect centered at (0,0,0) and with specified width/height
     - points must have sufficient space for 4 GLvertex3f's
     - Draw as stroke with GL_LINE_LOOP or fill with GL_TRIANGLE_FAN
     */
    void makeRect(GLvertex3f *points, float width, float height);
}


#endif
