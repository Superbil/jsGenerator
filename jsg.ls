#!/usr/bin/env lsc

fs = require 'fs'
path = require 'path'

schemadata = fs.readFileSync path.resolve('link.json'), 'utf8'
schema = JSON.parse schemadata
console.log schema                 # log

prefixString = "Popolo"
template_h = fs.readFileSync path.resolve('template_header.h'), 'utf8'
template_property = '''

/**
 {Property_Title}

 {Property_Description}
 */
@property (nonatomic, {Property_Status}) {Property_ClassName}{Property_Protocal} *{Property_Name};

'''
template_m = fs.readFileSync path.resolve('template_implementation.m'), 'utf8'
## ObjC_Implementation =

type_mapping =
    \string : \NSString
    \array : \NSArray

make_properties = ->
    result = ""
    for key, value of schema.properties
        r = template_property
        r = r.replace /{Property_Name}/ key
        r = r.replace /{Property_Title}/ key
        r = r.replace /{Property_Description}/ value.description if value.description

        r = r.replace /{Property_Status}/ ->
            ## TODO: must support weak
            if value.type is \string or \string in value.type then \copy else \strong

        r = r.replace /{Property_ClassName}/ ->
            name = ""
            classType =
                if value.type in type_mapping
                    type_mapping[value.type]
                else
                    "NSString"

            throw "Must had classType, #{value.type} -> #classType" if not classType
            name += classType
            name

        r = r.replace /{Property_Protocal}/ ->
            ## TODO: array need to create class name classname->Classname
            if \null in value.type
                \<Optional>
            else
                ""

        result += r
    result

make_header = ->
    h = template_h
    h = h.replace /{JSONSchemaURL}/g schema.id if schema.id
    h = h.replace /{JSONSchemaTitle}/g schema.title if schema.title
    h = h.replace /{ObjC_ClassName}/g prefixString + schema.title if prefixString + schema.title
    h = h.replace /{JSONSchemaDescription}/g schema.description if schema.description
    h = h.replace /{ObjC_Properties}/g make_properties! if schema.properties
    h

console.log make_header!          #log
## console.log template_m          #log
