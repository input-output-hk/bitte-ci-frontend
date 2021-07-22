enum Order {
  Organization
  PrNumber
}

enum Direction {
  Ascending
  Descending
}

component PullRequests {
  connect Application exposing { socket }

  state prs : Array(Model.PullRequest) = []
  state error : Maybe(String) = Maybe.nothing()
  state order : Order = Order::Organization
  state direction : Direction = Direction::Ascending

  fun componentDidMount {
    sequence {
      Application.setListener(["pull_requests", "builds"], onMsg)
      Application.subscribe()
    }
  }

  fun onMsg (msg : Msg) {
    case (msg) {
      Msg::PullRequests(prs) => next { prs = prs }
      => next { }
    }
  }

  fun render {
    <Container title="Pull Requests">
      if (Array.size(prs) > 0) {
        show()
      } else {
        <pre>
          <{ error or "not found" }>
        </pre>
      }
    </Container>
  }

  fun orderBy (key : Order) : Function(Html.Event, Promise(Never, Void)) {
    (event : Html.Event) : Promise(Never, Void) {
      next
        {
          order = key,
          direction =
            if (order == key) {
              case (direction) {
                Direction::Ascending => Direction::Descending
                Direction::Descending => Direction::Ascending
              }
            } else {
              direction
            }
        }
    }
  }

  fun sortedPrs {
    case (direction) {
      Direction::Ascending =>
        sorted
        |> Array.reverse()

      Direction::Descending =>
        sorted
    }
  } where {
    sorted =
      prs
      |> case (order) {
        Order::Organization =>
          Array.sortBy(
            (pr : Model.PullRequest) {
              pr.data.organization.login
            })

        Order::PrNumber =>
          Array.sortBy(
            (pr : Model.PullRequest) {
              pr.data.pullRequest.number
            })
      }
  }

  fun sortLink (label : String, key : Order) {
    <span
      onClick={orderBy(key)}
      style="white-space: pre;">

      <{ "#{label} " }>

      if (key == order) {
        <{
          case (direction) {
            Direction::Ascending => "↑"
            Direction::Descending => "↓"
          }
        }>
      } else {
        <{ "-" }>
      }

    </span>
  }

  fun show {
    <table class="table table-sm">
      <thead>
        <tr>
          <th>
            <{ sortLink("Org", Order::Organization) }>
          </th>

          <th>"Repo"</th>

          <th>
            <{ sortLink("#", Order::PrNumber) }>
          </th>

          <th>"Commit"</th>
          <th>"Branch"</th>
          <th>"Title"</th>
          <th>"Created"</th>
          <th>"Links"</th>
        </tr>
      </thead>

      <tbody>
        for (pr of sortedPrs()) {
          <PullRequestsRow pr={pr}/>
        }
      </tbody>
    </table>
  }
}

component PullRequestsRow {
  property pr : Model.PullRequest

  fun render {
    <tr>
      <td>
        <a href={orgUrl}>
          <img
            src={orgImg}
            style="height: 3em;">

            <{ orgName }>

          </img>
        </a>
      </td>

      <td>
        <a href={repoUrl}>
          <{ repoName }>
        </a>
      </td>

      <td>
        <a href={prUrl}>
          <{ number }>
        </a>
      </td>

      <td>
        <a href={commitUrl}>
          <{
            sha
            |> String.toArray()
            |> Array.take(7)
            |> String.fromArray()
          }>
        </a>
      </td>

      <td>
        <a href={branchUrl}>
          <{ ref }>
        </a>
      </td>

      <td>
        <{ title }>
      </td>

      <td>
        <{ createdAt }>
      </td>

      <td>
        <a href={"/pull_request/" + (Number.toString(pr.id))}>
          "Builds"
        </a>
      </td>
    </tr>
  } where {
    orgName =
      pr.data.organization.login

    orgImg =
      pr.data.organization.avatarUrl

    orgUrl =
      "https://github.com/" + orgName

    p =
      pr.data.pullRequest

    number =
      p.number
      |> Number.toString

    createdAt =
      p.createdAt
      |> Time.relative(Time.now())

    repoName =
      p.head.repo.fullName

    prUrl =
      p.htmlUrl

    title =
      p.title

    ref =
      p.head.ref

    sha =
      p.head.sha

    repoUrl =
      p.head.repo.htmlUrl

    commitUrl =
      repoUrl + "/commits/" + sha

    branchUrl =
      repoUrl + "/tree/" + ref
  }
}

record MsgPullRequests {
  pullRequests : Array(Model.PullRequest) using "pull_requests"
}
