# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

import
  std/json,
  std/os,
  std/re,
  std/strutils,
  std/tables

type
  RequestType = enum
    None
    Get
    Post
    Delete
    Head

  RequestBlock = ref object
    request: RequestType
    inPath: seq[string]
    inQuery: seq[string]
    responses: seq[ResponseCode]
    urlName: string
    summary: string
    ready: bool
    codeComment: seq[string]

  ResponseCode = ref object
    code: string
    text: string


proc jsonGet(inPath: seq[string], inQuery: seq[string], responses: seq[ResponseCode], urlName: string, summary, codeComment: string, requestType = "get"): JsonNode =
  ## Generates a GET request to the given URL.
  ##
  ## "/customer/{userid}/ok.php":{
  ##  "get": {
  ##    "summary": "List the details of customer by the ID",
  ##    "parameters": [{
  ##        "name": "id",
  ##        "in": "path",
  ##        "description": "UserID",
  ##        "required": true,
  ##        "type": "string"
  ##      },
  ##      {
  ##        "name": "userid",
  ##        "in": "path",
  ##        "description": "UserID",
  ##        "required": true,
  ##        "type": "string"
  ##      }
  ##    ],
  ##    "responses": {
  ##      "200": {
  ##        "description": "Details of the customer"
  ##      },
  ##      "400": {
  ##        "description": "ID required"
  ##      },
  ##      "404": {
  ##        "description": "Customer does not exist"
  ##      }
  ##    }
  ##  }
  ##  },
  var j = %* {
          requestType: {
            "summary": (if summary != "": summary else: urlName),
            "description": (if codeComment != "": codeComment else: ""),
            "parameters": [],
          }
        }

  for i in inPath:
    var p = %* {
                "name": i,
                "in": "path",
                "description": i,
                "required": true,
                "type": "string"
              }
    j[requestType]["parameters"].add(p)

  for i in inQuery:
    var p = %* {
                "name": i,
                "in": "query",
                "description": i,
                "required": true,
                "type": "string"
              }
    j[requestType]["parameters"].add(p)

  var resp: seq[string]
  if responses.len() == 0:
    resp.add("\"200\": { \"description\": \"200 - none specified directly\" }") # }))
  else:
    for i in responses:
      resp.add("\"" & i.code & "\": { \"description\":\"" & i.text.replace("\"", "'") & "\" }") # }))

  j[requestType]["responses"] = parseJson("{" & resp.join(",") & "}")

  return j





proc jsonPost(inPath: seq[string], inBody: seq[string], responses: seq[ResponseCode], urlName: string, summary, codeComment: string): JsonNode =
  ## Generates a GET request to the given URL.
  ##
  ## "/myprofile":{
  ##   "post":{
  ##     "summary":"/myprofile",
  ##     "parameters":[
  ##       {
  ##         "name":"email",
  ##         "in":"query",
  ##         "description":"email",
  ##         "required":false
  ##       }
  ##     ],
  ##     "requestBody":{
  ##       "content":{
  ##         "application/x-www-form-urlencoded":{
  ##           "schema":{
  ##             "type":"object",
  ##             "properties":{
  ##               "name":{
  ##                 "description":"name",
  ##                 "type":"string"
  ##               },
  ##               "status":{
  ##                 "description":"status",
  ##                 "type":"string"
  ##               }
  ##             }
  ##           }
  ##         }
  ##       }
  ##     },
  ##     "responses":{
  ##       "200":{
  ##         "description":"200"
  ##       },
  ##       "400":{
  ##         "description":"400"
  ##       },
  ##       "404":{
  ##         "description":"404"
  ##       }
  ##     }
  ##   }
  ## }
  var j = %* {
          "post": {
            "summary": (if summary != "": summary else: urlName),
            "description": (if codeComment != "": codeComment else: ""),
            "parameters": [],
          }
        }

  for i in inPath:
    var p = %* {
                "name": i,
                "in": "path",
                "description": i,
                "required": true,
              }
    j["post"]["parameters"].add(p)

  if inBody.len() > 0:
    var prop: seq[string]
    for i in inBody:
      prop.add(" \"" & i & "\"" & ": { \"description\":\"" & i & "\",\"type\":\"string\"}")

    var rb = %* {
      "content": {
        "application/x-www-form-urlencoded": {
          "schema": {
            "type": "object",
            "properties": parseJson("{" & prop.join(",") & "}")
          }
        }
      }
    }

    j["post"]["requestBody"] = rb

  var resp: seq[string]
  if responses.len() == 0:
    resp.add("\"200\": { \"description\": \"200 - none specified directly\" }") # }))
  else:
    for i in responses:
      resp.add("\"" & i.code & "\": { \"description\":\"" & i.text.replace("\"", "'") & "\" }") # }))

  j["post"]["responses"] = parseJson("{" & resp.join(",") & "}")

  return j



proc parseParamsInPath(s: var RequestBlock, line: string) = #: seq[string] =
  ## Parses the inPath from the given line.
  ## The params are identified by @, e.g. /api/@userID/profile.
  let parts = split(line, "/")
  for e in parts:
    if e.subStr(0,0) == "@":
      if e == parts[^1]:
        s.inPath.add(e.subStr(1,e.len()-3)) # Remove colon "/api/@eueu":
      else:
        s.inPath.add(e.subStr(1,e.len()-1))


proc parseParams(s: var RequestBlock, line: string) =
  ## Parses params used from either query (GET) or from body (POST).
  ## The params are identified by the @"contains-param" symbol.
  if line.contains("@\""):
    for f in findAll(line, re("""@"(.*?)"""")):
      let param = f.subStr(2,f.len()-2)
      if param notin s.inQuery and param notin s.inPath:
        s.inQuery.add(param)


proc parseReponse(s: var RequestBlock, line: string) =
  ## Parses the response codes from the given line.
  ## The response codes are identified by the Http[3-digits].
  if line.contains("resp"):
    if not line.contains(re"Http\d{3}"):
      s.responses.add(ResponseCode(code: "200", text: line))
    else:
      for f in findAll(line, re("""Http\d{3}""")):
        s.responses.add(ResponseCode(code: f[4..6], text: line))

  elif line.contains("redirect"):
    s.responses.add(ResponseCode(code: "301", text: line))



proc parseFile(filePath, baseUrl: string): JsonNode =

  var sCon: seq[RequestBlock]
  var multiComment: bool
  var count = -1
  var maybeCodeComment: bool

  for line in lines(filePath):
    let lineStrip = line.strip()

    #
    # Check for comments, empty lines and so on.
    #
    if multiComment:
      if lineStrip.contains("]#"):
        multiComment = false
      continue

    if lineStrip == "":
      continue

    if maybeCodeComment and lineStrip.subStr(0,1) == "##":
      sCon[count].codeComment.add(lineStrip.subStr(2,lineStrip.len()-1))

    if lineStrip.subStr(0,0) == "#":
      continue

    if lineStrip.contains("#["):
      multiComment = true
      continue

    #
    # Detect new routes route
    #
    if lineStrip.substr(0,2) == "get":
      var s: RequestBlock
      new(s)
      sCon.add(s)
      count += 1
      sCon[count].request = Get
      sCon[count].summary = lineStrip.replace("\"", "'")
      sCon[count].urlName = lineStrip.subStr(4,lineStrip.len()-2).replace("\"", "")
      parseParamsInPath(sCon[count], lineStrip)
      maybeCodeComment = true
      continue
    elif lineStrip.substr(0,3) == "post":
      var s: RequestBlock
      new(s)
      sCon.add(s)
      count += 1
      sCon[count].request = Post
      sCon[count].summary = lineStrip.replace("\"", "'")
      sCon[count].urlName = lineStrip.subStr(5,lineStrip.len()-2).replace("\"", "")
      parseParamsInPath(sCon[count], lineStrip)
      maybeCodeComment = true
      continue
    elif lineStrip.substr(0,5) == "delete":
      var s: RequestBlock
      new(s)
      sCon.add(s)
      count += 1
      sCon[count].request = Delete
      sCon[count].summary = lineStrip.replace("\"", "'")
      sCon[count].urlName = lineStrip.subStr(7,lineStrip.len()-2).replace("\"", "")
      parseParamsInPath(sCon[count], lineStrip)
      maybeCodeComment = true
      continue
    elif lineStrip.substr(0,3) == "head":
      var s: RequestBlock
      new(s)
      sCon.add(s)
      count += 1
      sCon[count].request = Head
      sCon[count].summary = lineStrip.replace("\"", "'")
      sCon[count].urlName = lineStrip.subStr(5,lineStrip.len()-2).replace("\"", "")
      parseParamsInPath(sCon[count], lineStrip)
      maybeCodeComment = true
      continue

    #
    # Blocker if no routes is yet detected.
    #
    if count == -1:
      continue

    # We have passed the route definition and first lines, so no ## code anymore for this route.
    maybeCodeComment = false

    # Parse params
    parseParams(sCon[count], lineStrip)

    # Parse responses
    parseReponse(sCon[count], lineStrip)


  #
  # Generate swagger routes
  #
  if sCon.len() == 0:
    return %* {}

  var swagCon: OrderedTable[string, JsonNode]
  for s in sCon:
    let urlFormat = s.urlName.replace("@", ":")
    if s.request in [Get, Delete, Head]:
      swagCon[urlFormat] = (jsonGet(s.inPath, s.inQuery, s.responses, s.urlName, urlFormat, s.codeComment.join("\n"), toLowerAscii($s.request)))
    elif s.request == Post:
      swagCon[urlFormat] = (jsonPost(s.inPath, s.inQuery, s.responses, s.urlName, urlFormat, s.codeComment.join("\n")))


  #
  # Combine swagger routes
  #
  var swag = %* {
    "swagger": "2.0",
    "info": {
      "title": splitFile(filePath).name,
      "description": "Jester routes converted to swagger JSON",
      "version": "1.0.0"
    },
    "host": baseUrl,
    "schemes":[
        "https"
    ],
    "paths": {},
  }

  for k, v in swagCon:
    swag["paths"][k] = v

  return swag


proc swagIt*(filepath: string, baseurl="", print=true, json=false, output="") =

  # Print swagger
  if not json and output == "":
    if filePath.contains("*"):
      echo "Error: filepath may not contain asterix (*) when printing to stdout."
      quit()
    echo pretty(%* parseFile(filepath, baseurl))

  # Save swagger
  else:
    var cfiles: seq[string]

    let outdir = if output == ".": getCurrentDir() else: output
    if not dirExists(outdir):
      echo "Error: output directory does not exist."
      quit()

    # Single swagger file
    if not filePath.contains("*"):
      if not fileExists(filePath):
        echo "Error: file does not exist."
        quit()
      let outdata = parseFile(filepath, baseurl)
      if outdata == %* {}:
        echo "  !! No data: " & filepath
      else:
        let swaggerName = splitFile(filepath).name & "_swagger.json"
        cfiles.add(swaggerName)
        writeFile(outdir / swaggerName, pretty(outdata))

    # Multiple swagger files
    else:
      for file in walkDir(splitFile(filepath).dir):
        if file.kind == pcFile:
          let outdata = parseFile(file.path, baseurl)
          if outdata == %* {}:
            echo "  !! No data: " & filepath
          else:
            let swaggerName = splitFile(file.path).name & "_swagger.json"
            cfiles.add(swaggerName)
            writeFile(outdir / swaggerName, pretty(outdata))

    echo "Created " & $cfiles.len() & " swagger files in " & outdir & "."
    for f in cfiles:
      echo "  " & f



when isMainModule:
  import cligen

  let topLvlUse = """
  $command {options}


OPTIONS
  -h, --help               Print this help message
  -f, --filepath  [string] Full path to the file to parse or * for whole directory
  -b, --baseurl   [string] Base url for the swagger routes
  -o, --output    [string] Output file for JSON file (use dot . for current directory)


CONFIG
  Jester => Swagger => Postman

  Default output is to stdout.

  Convert Jester-route files to Swagger 2.0 JSON. JSON is partly compliant
  with the Swagger 2.0 specification but allows for direct import in Postman.

  If `filepath` includes an asterix (*) all files in the directory will be
  converted (only available for output to file). Each file will generate it's
  own JSON file (aka Postman collection). Output is written to the current
  directory unless `output` is specified.

  `GET`, `POST`, `DELETE` and `HEAD` routes is supported.

INFO Swagger is making jokes
"""
  clCfg.hTabCols = @[clOptKeys, clDflVal, clDescrip]
  dispatch(swagIt,
          doc="Jester routes to Swagger JSON",
          cmdName="jester2swagger",
          usage=topLvlUse
          )