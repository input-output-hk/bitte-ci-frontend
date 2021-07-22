component Build {
  connect Application exposing { page }

  property id : String
  state build : Maybe(Model.Build) = Maybe.nothing()
  state logs : Map(String, Array(Model.LogLine)) = Map.empty()
  state error : Maybe(String) = Maybe.nothing()

  fun componentDidMount {
    sequence {
      Application.setListener(["build"], onMsg)
      Application.subscribe()
    }
  }

  fun onMsg (msg : Msg) {
    case (msg) {
      Msg::BuildWithLogs(m) =>
        next
          {
            build = Maybe.just(m.build),
            logs = m.logs
          }

      => next { }
    }
  }

  fun render {
    <Container title={"Build " + id}>
      case (build) {
        Maybe::Just(b) =>
          show(b)

        =>
          <pre>
            <{ error or "not found" }>
          </pre>
      }
    </Container>
  }

  fun show (build : Model.Build) {
    <div>
      <div>
        <a href={"/pull_request/" + Number.toString(build.prId)}>
          "Back to Pull Request"
        </a>
      </div>

      <hr/>

      <{
        for (uuid, lines of logs) {
          <div>
            <{ uuid }>

            <pre>
              <{
                for (line of lines) {
                  <{ "#{showTime(line.time)} #{line.line}\n" }>
                }
              }>
            </pre>
          </div>
        }
      }>
    </div>
  }

  fun showTime (time : Time) : String {
    time
    |> Time.format("Y-MM-dd HH:mm:ss")
  }

  fun showText (line : Array(String)) : String {
    Array.lastWithDefault("", line)
  }
}

record Model.LogLine {
  time : Time,
  line : String
}

record Model.BuildWithLogs {
  build : Model.Build,
  logs : Map(String, Array(Model.LogLine))
}

record Model.Build {
  id : String,
  prId : Number using "pr_id",
  status : String using "build_status",
  createdAt : Time using "created_at",
  finishedAt : Maybe(Time) using "created_at",
  updatedAt : Maybe(Time) using "updated_at"
}
