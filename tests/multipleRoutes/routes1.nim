router uno:

  get "/uno/@userID":
    if @"api" == "true":
      resp Http201
    resp Http200


  get "/uno/@userID/@name":
    if @"api" == "true":
      resp Http201
    resp Http200