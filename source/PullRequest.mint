component PullRequest {
  connect Application exposing { page }

  property id : Number
  state pr : Maybe(PullRequest) = Maybe.nothing()
  state error : Maybe(String) = Maybe.nothing()

  fun componentDidMount {
    sequence {
      Application.setListener(["pull_request", "builds", "allocations"], onMsg)
      Application.subscribe()
    }
  }

  fun onMsg (msg : Msg) {
    case (msg) {
      Msg::PullRequest(pr) => next { pr = Maybe.just(pr) }

      Msg::Allocation(alloc) =>
        sequence {
          Debug.log(alloc)
          next { }
        }

      Msg::Build(build) =>
        next
          {
            pr =
              Maybe.andThen(
                (p : PullRequest) : Maybe(PullRequest) {
                  Maybe.just(
                    { p | builds = updateBuild(p.builds, build) })
                },
                pr)
          }

      => next { }
    }
  }

  fun updateBuild (builds : Array(Build), build : Build) : Array(Build) {
    case (found) {
      Maybe::Just(elem) =>
        builds
        |> Array.setAt(Array.indexOf(elem, builds), build)

      Maybe::Nothing =>
        builds
        |> Array.push(build)
    }
  } where {
    found =
      Array.find((b : Build) : Bool { b.id == build.id }, builds)
  }

  fun catcher (err : Object.Error) {
    next
      {
        pr = Maybe.nothing(),
        error =
          Maybe.just(
            "failure: #{err
            |> Object.Error.toString}")
      }
  }

  fun render {
    <Container title="Pull Request">
      case (pr) {
        Maybe::Just(p) =>
          show(
            p.builds
            |> Array.sortBy((b : Build) : Number { -Time.getTime(b.createdAt) }),
            p.data.pullRequest)

        =>
          <pre>
            <{ error or "not found" }>
          </pre>
      }
    </Container>
  }

  fun show (builds : Array(Build), p : PullRequestInner) {
    <div>
      <div class="row">
        <h3 class="col">
          <{ p.title }>
        </h3>
      </div>

      <div class="row mt-5 mb-5">
        <div class="col col-sm-6">
          "Commit: #{p.head.sha} "

          <a href="#{p.head.repo.htmlUrl}/commits/#{p.head.sha}">
            <{ Icon.externalLink() }>
          </a>
        </div>

        <div class="col col-sm-3">
          "Pull Request: #{p.number} "

          <a href={p.htmlUrl}>
            <{ Icon.externalLink() }>
          </a>
        </div>

        <div class="col col-sm-3">
          "Branch: #{p.head.ref} "

          <a href={p.head.repo.htmlUrl + "/tree/" + p.head.ref}>
            <{ Icon.externalLink() }>
          </a>
        </div>

        <div class="col col-sm-2">
          "User: #{p.user.login} "

          <a href={p.user.htmlUrl}>
            <{ Icon.externalLink() }>
          </a>
        </div>
      </div>

      <table class="table table-md">
        <thead>
          <tr>
            <th>"Build"</th>
            <th>"Created"</th>
            <th>"Status"</th>
          </tr>
        </thead>

        <tbody>
          for (build of builds) {
            <tr>
              <td>
                <a href={"/build/" + build.id}>
                  <{ build.id }>
                </a>
              </td>

              <td>
                <{
                  build.createdAt
                  |> Time.relative(Time.now())
                }>
              </td>

              <td>
                <{ build.status }>
              </td>
            </tr>
          }
        </tbody>
      </table>
    </div>
  }
}

record Allocation {
  id : String,
  createdAt : Time using "created_at",
  updatedAt : Time using "updated_at",
  clientStatus : String using "client_status",
  index : Number,
  evalId : String using "eval_id"
}

record PullRequest {
  id : Number,
  data : PullRequestData,
  builds : Array(Build)
}

record PullRequestData {
  pullRequest : PullRequestInner using "pull_request"
}

record PullRequestInner {
  id : Number,
  createdAt : Time using "created_at",
  title : String,
  number : Number,
  htmlUrl : String using "html_url",
  head : PullRequestHead,
  user : PullRequestUser
}

record PullRequestHead {
  sha : String,
  ref : String,
  repo : PullRequestRepo
}

record PullRequestRepo {
  htmlUrl : String using "html_url"
}

record PullRequestUser {
  login : String,
  htmlUrl : String using "html_url"
}
