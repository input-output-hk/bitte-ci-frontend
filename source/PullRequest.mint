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
    case (pr) {
      Maybe::Just(justPr) =>
        if (build.prId == justPr.id) {
          case (Array.find((b : Build) : Bool { b.id == build.id }, builds)) {
            Maybe::Just(found) =>
              builds
              |> Array.setAt(Array.indexOf(found, builds), build)

            Maybe::Nothing => builds
          }
        } else {
          builds
        }

      Maybe::Nothing => builds
    }
  }

  fun catcher (err : Object.Error) {
    next
      {
        pr = Maybe.nothing(),
        error = Maybe.just("failure: #{msg}")
      }
  } where {
    msg =
      Object.Error.toString(err)
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
            <th>"Updated"</th>
            <th>"Finished"</th>
            <th>"Status"</th>
          </tr>
        </thead>

        <tbody>
          for (build of builds) {
            showBuild(build)
          }
        </tbody>
      </table>
    </div>
  }

  fun showBuild (build : Build) {
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
        <{
          case (build.updatedAt) {
            Maybe::Just(t) =>
              t
              |> Time.relative(Time.now())

            Maybe::Nothing => ""
          }
        }>
      </td>

      <td>
        <{
          case (build.finishedAt) {
            Maybe::Just(t) =>
              t
              |> Time.relative(Time.now())

            Maybe::Nothing => ""
          }
        }>
      </td>

      <td>
        <{ build.status }>
      </td>
    </tr>
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
  pullRequest : PullRequestInner using "pull_request",
  organization : PullRequestOrg
}

record PullRequestOrg {
  login : String,
  avatarUrl : String using "avatar_url"
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
  htmlUrl : String using "html_url",
  fullName : String using "full_name"
}

record PullRequestUser {
  login : String,
  htmlUrl : String using "html_url"
}
