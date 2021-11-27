# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

##
## This is a simple test file containing a router for Jester.
## We have some comments and other stuff for making it harder to parse.
##
## File contains dummy code.
##


router apiTokens:


  #
  # Raw JWT token handing
  #
  post "/api/token/jwt/request":
    ## User can request a new JWT token.

    if @"clientsAPI".len() > 500 or not @"userID".isValidDBIntNotEmpty():
      resp Http403, $(%* { "success": false, "msg": "Bad API key format"})

    let caData = getRowSafe(sql("SELECT api, keys FROM api WHERE a = ? AND u = ?"), @"clientsAPI", @"userID")

    if caData[0] == "" or caData[1] == "":
      resp Http400, $(%* { "success": false, "msg": "Bad API key"})

    let jwtToken = signToken(cID = caData[0], cKeys = caData[1], uID = @"userID", exp = 60.0)

    resp Http200, $(%* { "token": jwtToken, "expires": int(epochTime() + exp) })



  post "/api/token/@tokenType/verify":

    resp Http200, $(%* { "success": true, "valid": verifyToken(@"token") })


  get "/api/token/jwt/@signingServer/publickey":

    if @"signingServer" == "private":
      resp Http400
    elif @"signingServer" == "public" and @"alg" == "rs256":
      resp Http204, "123456789"

    resp Http204


  head "/":
    resp Http204


  get "/hello":
    resp "Hello"


  delete "/whole/server/@devil":
    echo @"devil"