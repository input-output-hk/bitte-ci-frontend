component PullRequest {
  connect Application exposing { page }

  property id : Number
  state pr : Maybe(Model.PullRequest) = Maybe.nothing()
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
          next { }
        }

      Msg::Build(build) =>
        next
          {
            pr =
              Maybe.andThen(
                (p : Model.PullRequest) : Maybe(Model.PullRequest) {
                  Maybe.just(
                    { p | builds = updateBuild(p.builds, build) })
                },
                pr)
          }

      => next { }
    }
  }

  fun updateBuild (builds : Array(Model.Build), build : Model.Build) : Array(Model.Build) {
    case (pr) {
      Maybe::Just(justPr) =>
        if (build.prId == justPr.id) {
          case (Array.find((b : Model.Build) : Bool { b.id == build.id }, builds)) {
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
            |> Array.sortBy((b : Model.Build) : Number { -Time.getTime(b.createdAt) }),
            p.data.pullRequest)

        =>
          <pre>
            <{ error or "not found" }>
          </pre>
      }
    </Container>
  }

  fun show (
    builds : Array(Model.Build),
    p : Model.PullRequestInner
  ) {
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

  fun showBuild (build : Model.Build) {
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

record Model.Output {
  id : String,
  path : String,
  createdAt : Time using "created_at",
  size : Number,
  mime : String
}

record Model.Allocation {
  id : String,
  createdAt : Time using "created_at",
  updatedAt : Time using "updated_at",
  clientStatus : String using "client_status",
  index : Number,
  evalId : String using "eval_id",
  outputs : Array(Model.Output)
}

record Model.PullRequest {
  id : Number,
  data : Model.PullRequestData,
  builds : Array(Model.Build)
}

record Model.PullRequestData {
  pullRequest : Model.PullRequestInner using "pull_request",
  organization : Model.PullRequestOrg
}

record Model.PullRequestOrg {
  login : String,
  avatarUrl : String using "avatar_url"
}

record Model.PullRequestInner {
  id : Number,
  createdAt : Time using "created_at",
  title : String,
  number : Number,
  htmlUrl : String using "html_url",
  head : Model.PullRequestHead,
  user : Model.PullRequestUser
}

record Model.PullRequestHead {
  sha : String,
  ref : String,
  repo : Model.PullRequestRepo
}

record Model.PullRequestRepo {
  htmlUrl : String using "html_url",
  fullName : String using "full_name"
}

record Model.PullRequestUser {
  login : String,
  htmlUrl : String using "html_url"
}
