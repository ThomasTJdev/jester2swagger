# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import std/os, std/sha1
import jester2swagger

test "parse single route file":
  swagIt("tests/test_routes.nim", baseurl="nim.nim", print=false, json=true, output="tests")
  check parseSecureHash("DDF849CAE5C20931C9709078DE502593814B6788") == secureHashFile("tests/test_routes_swagger.json")

test "parse directory":
  swagIt("tests/multipleRoutes/*", baseurl="nim.nim", print=false, json=true, output="tests/multipleRoutes")
  check fileExists("tests/multipleRoutes/routes1_swagger.json") == true
  check fileExists("tests/multipleRoutes/routes2_swagger.json") == true