component Main {
  connect Application exposing { page }

  fun render : Html {
    <div>
      <Navbar/>

      <{
        case (page) {
          Page::PullRequests =>
            <PullRequests/>

          Page::PullRequest(id) =>
            <PullRequest id={id}/>

          Page::Build(id) =>
            <Build id={id}/>
        }
      }>
    </div>
  }
}

routes {
  / {
    sequence {
      Application.setPage(Page::PullRequests)
    }
  }

  /pull_requests {
    Application.setPage(Page::PullRequests)
  }

  /build/:id (id : String) {
    Application.setPage(Page::Build(id))
  }

  /pull_request/:id (id : Number) {
    Application.setPage(Page::PullRequest(id))
  }
}
