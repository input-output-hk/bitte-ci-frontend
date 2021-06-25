component PullRequests {
  connect Application exposing { socket }

  state prs : Array(PullRequest) = []
  state error : Maybe(String) = Maybe.nothing()

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

  fun show {
    <table class="table table-sm">
      <thead>
        <tr>
          <th>"Repo"</th>
          <th>"#"</th>
          <th>"Commit"</th>
          <th>"Branch"</th>
          <th>"Title"</th>
          <th>"Created"</th>
          <th>"Links"</th>
        </tr>
      </thead>

      <tbody>
        for (pr of prs) {
          <PullRequestsRow pr={pr}/>
        }
      </tbody>
    </table>
  }
}

component PullRequestsRow {
  property pr : PullRequest

  fun render {
    <tr>
      <td>
        <a href={prUrl}>
          <{ number }>
        </a>
      </td>

      <td>
        <a href={prUrl}>
          <{ number }>
        </a>
      </td>

      <td>
        <a href={commitUrl}>
          <{ sha }>
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
    p =
      pr.data.pullRequest

    number =
      p.number
      |> Number.toString

    createdAt =
      p.createdAt
      |> Time.relative(Time.now())

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
  pullRequests : Array(PullRequest) using "pull_requests"
}
