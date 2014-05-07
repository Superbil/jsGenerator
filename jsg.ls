#!/usr/bin/env lsc

fs = require 'fs'
path = require 'path'

argv = require 'optimist'
  .usage('Usage: $0 -json <json file> -output [folder]')

  .demand(\json)
  .describe(\json, 'The JSON Schema file to create.')
  .alias(\json, \j)

  .options( \output,
      alias: \o
      default: 'output'
  )
  .describe(\output, 'Where to put output.')

  .argv

schemadata = fs.readFileSync path.resolve(argv.json), 'utf8'
schema = JSON.parse schemadata
#console.log schema                 # log
throw "Must had schema.title" if not schema.title

prefixString = "Popolo"

newTitle = ->
    capitaliseFirstLetter = (name) -> name.charAt(0).toUpperCase! + name.slice 1
    title = ""
    [title += capitaliseFirstLetter s for s in schema.title.split " "]
    ## remove space between words
    title.replace " ", ""
className = prefixString + newTitle!

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
    h = h.replace /{JSONSchemaTitle}/g schema.title
    h = h.replace /{ObjC_ClassName}/g className
    h = h.replace /{JSONSchemaDescription}/g schema.description if schema.description
    h = h.replace /{ObjC_Properties}/g make_properties! if schema.properties
    h

make_implement = ->
   m = template_m
   m = m.replace /{ObjC_ClassName}/g className
   m = m.replace /{ObjC_Implementation}/g ""
   m

fs.mkdirSync path.resolve argv.output if not fs.existsSync path.resolve argv.output
## console.log make_header!        #log
console.log "Making... #{className}.h"
fs.writeFileSync path.resolve(argv.output, "#{className}.h"), make_header!
## console.log make_implement!     #log
console.log "Making... #{className}.m"
fs.writeFileSync path.resolve(argv.output, "#{className}.m"), make_implement!
