<img src="private/jestermyswagger.png" style="display: inline; max-height: 300px">

# jester2swagger

**jester** => **swagger** => **postman**


This hybrid package transforms routes from [Jester](https://github.com/dom96/jester)
to [Swagger](https://swagger.io/) JSON. The purpose is to generate a Swagger
JSON file that can be imported directly into Postman.

Run `jester2swagger` on your Jester routes and voila, you have a Swagger JSON
file that can be imported directly into Postman.

Okay, this is not a 100% compliant with the Swagger specification, but it
works fine for generating a Swagger JSON file that can be imported without
any hassle into Postman.

# Generating Swagger JSON

## Print it
You can just print directly to stdout and enjoy your Swagger JSON:
```shell
$ jester2swagger -f routes/apiRoutes.nim
```

## Parse one file
Create a single Swagger JSON file from a single Jester route file in the folder `swagger/folder`-
```shell
$ jester2swagger -f routes/apiRoutes.nim -o swagger/folder
```

## Parse many file
The key here is the `*` wildcard. All files within the folder will parsed.
```shell
$ jester2swagger -f routes/* -o swagger/folder
```

# Example output

An output file can found in the `tests` folder named `test_routes_swagger.example.json`.

# Supported route items

- Files containing Jester router or Jester routes
- `GET`, `POST`, `DELETE` and `HEAD` routes is supported.
- Specified Http-responses (`resp Http204`) or indirected (`redirect "/"`, `resp "OK"`)
- Nim comments just below the route (`## Double hashtags are supported`)
- In-path parameters are supported (`/users/@id`)
- In-query parameters are supported (`/users?id=value`)
- In-body parameters are supported (`@"userID"`)


# Library

```nim
import jester2swagger

swagIt("tests/test_routes.nim", baseurl="nim-lang.org", print=true)
```


# CLI tool

```shell
$ ./jester2swagger --help
Usage:
    jester2swagger {options}


OPTIONS
  -h, --help      Print this help message
  -f, --filepath  Full path to the file to parse or * for whole directory
  -b, --baseurl   Base url for the swagger routes
  -p, --print     Print the swagger routes to stdout
  -j, --json      Save output to JSON file
  -o, --output    Output file for JSON file (defaults to current directory)


CONFIG
  Convert Jester-route files to Swagger 2.0 JSON. JSON is partly compliant
  with the Swagger 2.0 specification but allows for direct import in Postman.

  If `filepath` includes an asterix (*) all files in the directory will be
  converted (only available for output to file). Each file will generate it's
  own JSON file (aka Postman collection).

  Output is written to the current directory unless `output` is specified.

  `GET`, `POST`, `DELETE` and `HEAD` routes is supported.

INFO Swagger is making jokes
```