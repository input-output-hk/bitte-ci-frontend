component Allocation {
  property logs : Array(Array(String))

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

  fun render {
    <pre>
      <{
        for (line of logs) {
          <{ showTime(line) + " " + showText(line) + "\n" }>
        }
      }>
    </pre>
  }
}
