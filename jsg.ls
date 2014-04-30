#!/usr/bin/env lsc

fs = require 'fs'
path = require 'path'

schemafile = path.resolve 'link.json'
schemadata = fs.readFileSync schemafile, 'utf8'
raw = JSON.parse schemadata
console.log raw

prefixString = "Popolo"
template_h = fs.readFileSync path.resolve('template_header.h'), 'utf8'
template_property = "
/**
 {Property_Title}

 {Property_Description}
 */
@property (nonatomic, {Property_status}) {Property_ClassName} *{Property_Name};
"
template_m = fs.readFileSync path.resolve('template_implementation.m'), 'utf8'
## ObjC_Implementation =

template_h.replace /{ObjC_ClassName}/g "Link"


for key, value of raw
    switch key
    case \id
        then \id
    case \title
        then \title
    case \description
        then \description
    case \properties
        for pk, pv of value
            console.log "#pk, #pv"
