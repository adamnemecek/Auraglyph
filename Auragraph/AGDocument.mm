//
//  AGDocument.cpp
//  Auragraph
//
//  Created by Spencer Salazar on 11/21/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#include "AGDocument.h"

#include "AGNode.h"
#include "AGConnection.h"

#include "spstl.h"
#include "NSString+STLString.h"


static NSString *filenameForTitle(string title)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [[basePath stringByAppendingPathComponent:[NSString stringWithCString:title.c_str() encoding:NSUTF8StringEncoding]] stringByAppendingPathExtension:@"json"];
}


AGDocument::AGDocument() :
m_title("") { }

AGDocument::~AGDocument()
{ }

void AGDocument::addNode(const Node &node)
{
    m_nodes[node.uuid] = node;
}

void AGDocument::updateNode(const string &uuid, const Node &update)
{
    m_nodes[uuid] = update;
}

void AGDocument::removeNode(const string &uuid)
{
    m_nodes.erase(uuid);
}

void AGDocument::addConnection(const Connection &connection)
{
    m_connections[connection.uuid] = connection;
}

void AGDocument::removeConnection(const string &uuid)
{
    m_connections.erase(uuid);
}

void AGDocument::addFreedraw(const Freedraw &freedraw)
{
    m_freedraws[freedraw.uuid] = freedraw;
}

void AGDocument::updateFreedraw(const string &uuid, const Freedraw &update)
{
    m_freedraws[uuid] = update;
}

void AGDocument::removeFreedraw(const string &uuid)
{
    m_freedraws.erase(uuid);
}

void AGDocument::create()
{
    
}

void AGDocument::load(const string &title)
{
    m_title = title;
    
    NSString *filename = filenameForTitle(m_title);
    NSData *data = [NSData dataWithContentsOfFile:filename];
    NSDictionary *doc = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    
    if(doc)
    {
        for(NSString *key in doc)
        {
            NSDictionary *dict = doc[key];
            NSString *object = dict[@"object"];
            
            if([object isEqualToString:@"node"])
            {
                Node n;
                n.uuid = [key stlString];
                n._class = (AGDocument::Node::Class) [dict[@"class"] intValue];
                n.type = [dict[@"type"] stlString];
                n.x = [dict[@"x"] floatValue]; n.y = [dict[@"y"] floatValue]; n.z = [dict[@"z"] floatValue];
                
                if([dict objectForKey:@"params"])
                {
                    for(NSString *param in dict[@"params"])
                    {
                        ParamValue pv;
                        
                        NSDictionary *value = dict[@"params"][param];
                        if([value[@"type"] isEqualToString:@"int"]) { pv.type = ParamValue::INT; pv.i = [value[@"value"] intValue]; }
                        else if([value[@"type"] isEqualToString:@"float"]) { pv.type = ParamValue::FLOAT; pv.f = [value[@"value"] floatValue]; }
                        else if([value[@"type"] isEqualToString:@"string"]) { pv.type = ParamValue::STRING; pv.s = [[value[@"value"] stringValue] UTF8String]; }
                        else assert(0); // unhandled
                        
                        n.params[[param UTF8String]] = pv;
                    }
                }
                
                m_nodes[n.uuid] = n;
            }
            else if([object isEqualToString:@"connection"])
            {
                Connection c;
                
                c.uuid = [key stlString];
                c.srcUuid = [dict[@"source"] stlString];
                c.dstUuid = [dict[@"destination"] stlString];
                
                m_connections[c.uuid] = c;
            }
            else if([object isEqualToString:@"freedraw"])
            {
                Freedraw f;
                
                f.uuid = [key stlString];
                f.x = [dict[@"x"] floatValue]; f.y = [dict[@"y"] floatValue]; f.z = [dict[@"z"] floatValue];
                f.points.reserve([dict[@"points"] count]);
                for(NSNumber *num in dict[@"points"])
                    f.points.push_back([num floatValue]);
                
                m_freedraws[f.uuid] = f;
            }
            else
            {
                NSLog(@"AGDocument::load: error: unhandled object '%@'", object);
            }
        }
    }
}

void AGDocument::save()
{
    NSMutableDictionary *doc = [NSMutableDictionary new];
    
    itmap(m_nodes, ^(pair<const string, Node> &val){
        const string &uuid = val.first;
        Node &node = val.second;
        
        NSMutableDictionary *params = [NSMutableDictionary new];
        itmap(node.params, ^(pair<const string, ParamValue> &param){
            NSString *serialType = nil;
            id serialValue = nil;
            
            switch(param.second.type)
            {
                case ParamValue::INT: serialValue = @(param.second.i); serialType = @"int"; break;
                case ParamValue::FLOAT: serialValue = @(param.second.f); serialType = @"float"; break;
                case ParamValue::STRING: serialValue = [NSString stringWithSTLString:param.second.s]; serialType = @"string"; break;
                case ParamValue::FLOAT_ARRAY:
                     serialType = @"array_float";
                    serialValue = [NSMutableArray arrayWithCapacity:param.second.fa.size()];
                    itmap(param.second.fa, ^(float &f){
                        [serialValue addObject:@(f)];
                    });
                    break;
            }
            
            [params setObject:@{ @"type": serialType, @"value": serialValue }
                       forKey:[NSString stringWithSTLString:param.first]];
        });
        
        [doc setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        @"node", @"object",
                        @((int) node._class), @"class",
                        [NSString stringWithSTLString:node.type], @"type",
                        @(node.x), @"x", @(node.y), @"y", @(node.z), @"z",
                        params, @"params",
                        nil]
                forKey:[NSString stringWithSTLString:uuid]];
    });
    
    itmap(m_connections, ^(pair<const string, Connection> &val){
        const string &uuid = val.first;
        Connection &conn = val.second;
        
        [doc setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        @"connection", @"object",
                        [NSString stringWithSTLString:conn.srcUuid], @"source",
                        [NSString stringWithSTLString:conn.dstUuid], @"destination",
                        nil]
                forKey:[NSString stringWithSTLString:uuid]];
    });
    
    itmap(m_freedraws, ^(pair<const string, Freedraw> &val){
        const string &uuid = val.first;
        Freedraw &fd = val.second;
        
        NSMutableArray *points = [NSMutableArray arrayWithCapacity:fd.points.size()];
        itmap(fd.points, ^(float &f){
            [points addObject:@(f)];
        });
        
        [doc setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        @"freedraw", @"object",
                        @(fd.x), @"x", @(fd.y), @"y", @(fd.z), @"z",
                        points, @"points",
                        nil]
                forKey:[NSString stringWithSTLString:uuid]];
    });
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:doc
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:NULL];
    NSString *filepath = filenameForTitle(m_title);
    NSLog(@"Saving to %@", filepath);
    [data writeToFile:filepath atomically:YES];
}

void AGDocument::saveTo(const string &title)
{
    m_title = title;
    save();
}

void AGDocument::recreate(void (^createNode)(const Node &node),
                          void (^createConnection)(const Connection &connection),
                          void (^createFreedraw)(const Freedraw &freedraw))
{
    itmap(m_nodes, ^(pair<const string, Node> &kv){
        createNode(kv.second);
    });
    itmap(m_connections, ^(pair<const string, Connection> &kv){
        createConnection(kv.second);
    });
    itmap(m_freedraws, ^(pair<const string, Freedraw> &kv){
        createFreedraw(kv.second);
    });
}


bool AGDocument::existsForTitle(const string &title)
{
    NSString *filename = filenameForTitle(title);
    return [[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:NULL];
}

