component Allocation {
  connect Application exposing { page }

  property id : String
  property logs : Array(Array(String)) = [["2000", "b"]]

  state alloc : Maybe(Model.Allocation) =
    Maybe.just(
      {
        id = "2af2276b-a87d-492f-992e-90ae6e5a5bae",
        createdAt = Time.now(),
        updatedAt = Time.now(),
        clientStatus = "complete",
        index = 12,
        evalId = "80a07ef3-a1aa-41d6-8431-3b0078c243ec",
        outputs =
          [
            {
              id = "dea0e39b-2902-4e85-b6f6-c41a3bf55f55",
              path = "/local/test.txt",
              createdAt = Time.now(),
              size = 1234,
              mime = "application/json"
            }
          ]
      })

  fun componentDidMount {
    sequence {
      Application.setListener(["allocation"], onMsg)
      Application.subscribe()
    }
  }

  fun onMsg (msg : Msg) {
    case (msg) {
      Msg::Allocation(alloc) => next { alloc = Maybe.just(alloc) }
      => next { alloc = Maybe.nothing() }
    }
  }

  fun showTime (line : Array(String)) : String {
    case (Array.first(line)) {
      Maybe::Just(time) =>
        case (Time.fromIso(time)) {
          Maybe::Just(validTime) =>
            validTime
            |> Time.format("Y-MM-dd HH:mm:ss")

          Maybe::Nothing => "invalid time"
        }

      Maybe::Nothing => "invalid time"
    }
  }

  fun showText (line : Array(String)) : String {
    Array.lastWithDefault("", line)
  }

  fun render {
    <Container title="Allocation">
      case (alloc) {
        Maybe::Just(a) =>
          <table class="table">
            <thead>
              <tr>
                <th>"ID"</th>
                <th>"Path"</th>
                <th>"Created"</th>
                <th>"Size"</th>
                <th>"Mime"</th>
              </tr>
            </thead>

            <tbody>
              <{
                for (output of a.outputs) {
                  <tr>
                    <td>
                      <a
                        href="/api/v1/output/#{output.id}"
                        target="_blank">

                        <{ output.path }>

                      </a>
                    </td>

                    <td>
                      <{
                        output.createdAt
                        |> Time.format("Y-MM-dd HH:mm:ss")
                      }>
                    </td>

                    <td>
                      <{
                        output.size
                        |> Number.toString
                      }>
                    </td>

                    <td>
                      <{ output.mime }>
                    </td>
                  </tr>
                }
              }>
            </tbody>
          </table>

        Maybe::Nothing => <{ "" }>
      }

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
