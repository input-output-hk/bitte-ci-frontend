enum Msg {
  PullRequest(PullRequest)
  PullRequests(Array(PullRequest))
  Allocation(Allocation)
  Build(Build)
  BuildWithLogs(BuildWithLogs)
}

store Application {
  state page : Page = Page::PullRequests
  state error : Maybe(String) = Maybe.nothing()
  state socket : Maybe(WebSocket) = Maybe.nothing()
  state topics : Array(String) = []

  state listener : Function(Msg, Promise(Never, Void)) =
    (m : Msg) {
      next { }
    }

  fun decodeMsg (object : Object) : Result(Object.Error, Msg) {
    `
    (() => {
    	try {
        console.debug(#{object})
        switch (#{type}) {
        case "pull_request": return #{try {
            dec = decode value as PullRequest
            Result::Ok(Msg::PullRequest(dec))
          } catch Object.Error => err { Result::Err(Object.Error.toString(err)) }}
        case "pull_requests": return #{try {
            dec = decode value as Array(PullRequest)
            Result::Ok(Msg::PullRequests(dec))
          } catch Object.Error => err { Result::Err(Object.Error.toString(err)) }}
        case "build": return #{try {
            dec = decode value as BuildWithLogs
            Result::Ok(Msg::BuildWithLogs(dec))
          } catch Object.Error => err { Result::Err(Object.Error.toString(err)) }}
        case "builds": return #{try {
            dec = decode value as Build
            Result::Ok(Msg::Build(dec))
          } catch Object.Error => err { Result::Err(Object.Error.toString(err)) }}
        case "allocations": return #{try {
            dec = decode value as Allocation
            Result::Ok(Msg::Allocation(dec))
          } catch Object.Error => err { Result::Err(Object.Error.toString(err)) }}
        default:
        	return #{Result::Err("Don't know how to decodeMsg: " + type)}
        }
      } catch(e) {
      	return #{Result::Err(`e`)}
      }
    })()
    `
  } where {
    type =
      `(() => { return #{object}.type })()`

    value =
      `(() => { return #{object}.value })()`
  }

  fun setListener (
    topics : Array(String),
    listener : Function(Msg, Promise(Never, Void))
  ) {
    next
      {
        topics = topics,
        listener = listener
      }
  }

  fun setPage (page : Page) {
    case (socket) {
      Maybe::Just(open) =>
        sequence {
          subPage(open, page)

          next { page = page }
        }

      Maybe::Nothing =>
        next { page = page }
    }
  }

  fun subscribe : Promise(Never, Void) {
    next
      {
        socket =
          Maybe.just(
            socket
            |> Maybe.withLazyDefault(
              () {
                WebSocket.open(
                  {
                    url = wsUrl(),
                    reconnectOnClose = true,
                    onMessage = onMessage,
                    onOpen = onOpen,
                    onError = handleError,
                    onClose = handleClose
                  })
              }))
      }
  }

  fun wsUrl {
    if (url.protocol == "https") {
      "wss://" + url.host + "/ci/api/v1/socket"
    } else {
      "ws://" + url.host + "/ci/api/v1/socket"
    }
  } where {
    url =
      Window.url()
  }

  fun onMessageInvalid (type : String, obj : Object) : Promise(Never, Void) {
    next { error = Maybe.just("Unknown message type: " + type) }
  }

  fun onMessage (msg : String) : Promise(Never, Void) {
    sequence {
      json =
        msg
        |> Json.parse
        |> Maybe.toResult("Decoding WS JSON failed")

      res =
        json
        |> decodeMsg

      listener(res)

      next { }
    } catch String => err {
      next { error = Maybe.just(err) }
    } catch Object.Error => err {
      next { error = Maybe.just(Object.Error.toString(err)) }
    }
  }

  fun handleError : Promise(Never, Void) {
    next { error = Maybe.just("Websocket failed") }
  }

  fun handleClose : Promise(Never, Void) {
    next { socket = Maybe.nothing() }
  }

  fun onOpen (socket : WebSocket) : Promise(Never, Void) {
    sequence {
      subPage(socket, page)
      next { socket = Maybe.just(socket) }
    }
  }

  fun subChannel (socket : WebSocket, obj : Object) {
    WebSocket.send(
      obj
      |> Json.stringify,
      socket)
  }

  fun subPage (socket : WebSocket, page : Page) : Promise(Never, Void) {
    case (page) {
      Page::PullRequests =>
        subChannel(socket, encode { channel = "pull_requests" })

      Page::PullRequest(id) =>
        subChannel(
          socket,
          encode {
            channel = "pull_request",
            id = id
          })

      Page::Build(id) =>
        subChannel(
          socket,
          encode {
            channel = "build",
            uuid = id
          })
    }
  }
}
