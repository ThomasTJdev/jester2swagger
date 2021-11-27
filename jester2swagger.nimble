# Package

version       = "0.1.0"
author        = "ThomasTJdev"
description   = "Generate Swagger JSON from Jester-routes"
license       = "MIT"
bin           = @["jester2swagger"]
installExt    = @["jester2swagger"]

# Dependencies

requires "nim >= 1.4.8"
requires "cligen >= 1.5.3"