#!/usr/bin/env lsc
## -*- tab-width: 2; -*-

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

newTitle = (inputTitle) ->
  capitaliseFirstLetter = (name) -> name.charAt(0).toUpperCase! + name.slice 1
  title = ""
  [title += capitaliseFirstLetter s for s in inputTitle.split " "]
  ## remove space between words
  title.replace " ", ""
className = prefixString + newTitle schema.title

template_h = fs.readFileSync path.resolve('template_header.h'), 'utf8'
template_property = '''

/**
 {Property_Title}

 {Property_Description}
 */
@property (nonatomic, {Property_Status}) {Property_ClassName}{Property_Protocal} *{Property_Name};

'''
template_m = fs.readFileSync path.resolve('template_implementation.m'), 'utf8'

type_mapping =
  \string : \NSString
  \array : \NSArray

make_properties = ->
  result = ""
  for key, value of schema.properties
    p = template_property
    p = p.replace /{Property_Name}/ key
    p = p.replace /{Property_Title}/ key
    p = p.replace /{Property_Description}/ value.description if value.description
    p = p.replace /{Property_Status}/ ->
      ## TODO: must support weak
      if value.type is \string then \copy else \strong
    p = p.replace /{Property_ClassName}/ ->
      name = ""
      t = typeof value.type
      classType =
        if value.type in type_mapping
          type_mapping[value.type]
        else if value.type is /array/
          \NSArray
        else
          \NSString
      throw "Must had classType, #{value.type} -> #classType" if not classType
      name += classType
      name
    #console.log "value key:#{key}  type: #{value.type}"
    p = p.replace /{Property_Protocal}/ ->
      c = []
      if value.type is /array/
        findName = ->
          n = ""
          [n = v for k, v of value.items]
          n = n.split /.+\/(\w+).json.?$/
          n = n[1].replace /_/ " "
          prefixString + newTitle n
        c += findName!

      if value.type? and \null in value.type
        c += \Optional
      else
        ""

      if c.length > 0 then
        "<#c>"
      else
        ""

    result += p
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
