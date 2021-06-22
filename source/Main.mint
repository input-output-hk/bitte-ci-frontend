enum Page {
  Jobs
  Job
}

routes {
  / {
    sequence {
      Application.subscribe()
      Application.setPage(Page::Jobs)
    }
  }

  /job/:uuid (uuid : String) {
    sequence {
      Application.setUUID(uuid)
      Application.subscribe()
      Application.setPage(Page::Job)
    }
  }
}

module Time {
  fun getTime (date : Time) : Number {
    `
    (() => {
      return #{date}.getTime()
    })()
    `
  }
}

record Job {
  id : String,
  createdAt : Time using "created_at",
  updatedAt : Time using "updated_at",
  step : String,
  avatar : String,
  login : String,
  senderUrl : String using "sender_url",
  headLabel : String using "head_label",
  headRef : String using "head_ref"
}

record Msg {
  type : String,
  jobs : Maybe(Array(Job)),
  job : Maybe(Job),
  logs : Maybe(Array(Array(String))),
  event : Maybe(Job)
}

store Application {
  state page : Page = Page::Jobs
  state error : Maybe(String) = Maybe.nothing()
  state logs : Array(Array(String)) = []
  state uuid : String = ""
  state jobs : Map(String, Job) = Map.empty()
  state socket : Maybe(WebSocket) = Maybe.nothing()

  fun setPage (page : Page) {
    case (socket) {
      Maybe::Just(open) =>
        sequence {
          subPage(open, page)

          next
            {
              page = page,
              logs = []
            }
        }

      Maybe::Nothing =>
        next
          {
            page = page,
            logs = []
          }
    }
  }

  fun setUUID (uuid : String) : Promise(Never, Void) {
    next { uuid = uuid }
  }

  get job : Maybe(Job) {
    jobs
    |> Map.get(uuid)
  }

  fun subscribe : Promise(Never, Void) {
    if (Maybe.isNothing(socket)) {
      sequence {
        WebSocket.open(
          {
            url = "ws://127.0.0.1:3120/ci/api/v1/socket",
            reconnectOnClose = true,
            onMessage = onMessage,
            onOpen = onOpen,
            onError = handleError,
            onClose = handleClose
          })

        next { }
      }
    } else {
      next { }
    }
  }

  fun onMessage (msg : String) : Promise(Never, Void) {
    sequence {
      json =
        msg
        |> Json.parse()
        |> Maybe.toResult("Decoding WS JSON failed")

      value =
        decode json as Msg

      case (value.type) {
        "logs" =>
          case (value.logs) {
            Maybe::Just(logs) =>
              next
                {
                  logs = logs,
                  error = Maybe.nothing()
                }

            Maybe::Nothing => next { error = Maybe.just("invalid logs received") }
          }

        "job" =>
          case (value.event) {
            Maybe::Just(event) =>
              next
                {
                  jobs = Map.set(event.id, event, jobs),
                  error = Maybe.nothing()
                }

            Maybe::Nothing => next { error = Maybe.just("invalid job event") }
          }

        "jobs" =>
          case (value.jobs) {
            Maybe::Just(jobs) =>
              next
                {
                  jobs =
                    jobs
                    |> Array.map(
                      (job : Job) : Tuple(String, Job) {
                        {job.id, job}
                      })
                    |> Map.fromArray(),
                  error = Maybe.nothing()
                }

            Maybe::Nothing => next { error = Maybe.just("invalid jobs received") }
          }

        => next { error = Maybe.just("Unknown message type: " + value.type) }
      }
    } catch String => err {
      next { error = Maybe.just(err) }
    } catch Object.Error => err {
      next { error = Maybe.just("Couldn't decode Job") }
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

  fun subPage (socket : WebSocket, page : Page) : Promise(Never, Void) {
    case (page) {
      Page::Jobs =>
        WebSocket.send(
          (encode { channel = "jobs" })
          |> Json.stringify(),
          socket)

      Page::Job =>
        parallel {
          WebSocket.send(
            (encode { channel = "jobs" })
            |> Json.stringify(),
            socket)

          WebSocket.send(
            (encode {
              channel = "logs",
              uuid = uuid
            })
            |> Json.stringify(),
            socket)
        }
    }
  }
}

component Main {
  connect Application exposing { page, job }

  fun render : Html {
    <div>
      <Navbar/>

      <{
        case (page) {
          Page::Jobs => <Jobs/>

          Page::Job =>
            case (job) {
              Maybe::Just(found) => <Job job={found}/>
              Maybe::Nothing => <NotFound/>
            }
        }
      }>
    </div>
  }
}

component NotFound {
  fun render : Html {
    <Container title="Page not found"/>
  }
}

component Job {
  connect Application exposing { error, logs }
  property job : Job

  fun showTime (line : Array(String)) : String {
    case (Array.first(line)) {
      Maybe::Just(time) =>
        case (Time.fromIso(time)) {
          Maybe::Just(validTime) =>
            validTime
            |> Time.format("Y-MM-dd HH:mm:ss")

          Maybe::Nothing => ""
        }

      Maybe::Nothing => ""
    }
  }

  fun showText (line : Array(String)) : String {
    Array.lastWithDefault("", line)
  }

  fun render : Html {
    <Container title={"Job " + job.id}>
      <table>
        <tr>
          <td>
            <{ job.headLabel }>
          </td>
        </tr>
      </table>

      <pre>
        <{
          for (line of logs) {
            <{ showTime(line) + " " + showText(line) + "\n" }>
          }
        }>
      </pre>
    </Container>
  }
}

component Container {
  connect Application exposing { error }
  property title : String
  property children : Array(Html) = []

  fun render : Html {
    <div class="container">
      <div class="row">
        <div class="col">
          <h2>
            <{ title }>
          </h2>

          <If condition={Maybe.isJust(error)}>
            <div>
              "error: "

              <{
                error
                |> Maybe.withDefault("")
              }>
            </div>
          </If>
        </div>
      </div>

      <{ children }>
    </div>
  }
}

component Jobs {
  connect Application exposing { error, jobs }

  fun sortedJobs : Map(String, Job) {
    jobs
    |> Map.sortBy(
      (key : String, value : Job) : Number {
        -Time.getTime(value.createdAt)
      })
  }

  fun render : Html {
    <Container title="Jobs in the last 24 hours">
      <div class="row">
        <div class="col">
          <table class="table table-sm">
            <thead>
              <tr>
                <td>"Sender"</td>
                <td>"Label"</td>
                <td>"Created"</td>
                <td>"Updated"</td>
                <td>"Step"</td>
              </tr>
            </thead>

            <tbody>
              for (id, job of sortedJobs()) {
                <tr>
                  <td>
                    <a href={job.senderUrl}>
                      <img
                        width="32"
                        height="32"
                        alt={job.login}
                        src={job.avatar}/>
                    </a>
                  </td>

                  <td>
                    <a href={"/job/" + job.id}>
                      <{ job.headLabel }>
                    </a>
                  </td>

                  <td>
                    <{
                      job.createdAt
                      |> Time.relative(Time.now())
                    }>
                  </td>

                  <td>
                    <{
                      job.updatedAt
                      |> Time.relative(Time.now())
                    }>
                  </td>

                  <td>
                    <{ job.step }>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </div>
    </Container>
  }
}

component Navbar {
  fun render : Html {
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
      <div class="container-fluid">
        <a
          class="navbar-brand"
          href="#">

          "Bitte CI"

        </a>

        <button
          class="navbar-toggler"
          type="button"
          data-bs-toggle="collapse"
          data-bs-target="#navbarSupportedContent"
          aria-controls="navbarSupportedContent"
          aria-expanded="false"
          aria-label="Toggle navigation">

          <span class="navbar-toggler-icon"/>

        </button>

        <div
          class="collapse navbar-collapse"
          id="navbarSupportedContent">

          <ul class="navbar-nav me-auto mb-2 mb-lg-0">
            <li class="nav-item">
              <a
                class="nav-link active"
                aria-current="page"
                href="/">

                "Home"

              </a>
            </li>
          </ul>

        </div>
      </div>
    </nav>
  }
}
