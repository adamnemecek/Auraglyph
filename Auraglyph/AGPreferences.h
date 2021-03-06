//
//  AGPreferences.hpp
//  Auragraph
//
//  Created by Spencer Salazar on 11/21/16.
//  Copyright © 2016 Spencer Salazar. All rights reserved.
//

#ifndef AGPreferences_h
#define AGPreferences_h

#include <string>

//------------------------------------------------------------------------------
// ### AGPreferences ###
// Abstraction for preferences management
//------------------------------------------------------------------------------
#pragma mark - AGPreferences

class AGPreferences
{
public:
    static AGPreferences &instance();
    
    AGPreferences();
    
    void setLastOpenedDocument(const std::string &filename);
    std::string lastOpenedDocument();
};


#endif /* AGPreferences_h */
