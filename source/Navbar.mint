component Navbar {
  connect Application exposing { page }

  fun render : Html {
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
      <div class="container-fluid">
        <a
          class="navbar-brand"
          href="/">

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
            <{ navItem("Pull Requests", "/pull_requests") }>
          </ul>

        </div>
      </div>
    </nav>
  }

  fun navItem (name : String, href : String) : Html {
    <li class="nav-item">
      if (active) {
        <a
          class="nav-link active"
          aria-current="page"
          href={href}>

          <{ name }>

        </a>
      } else {
        <a
          class="nav-link"
          href={href}>

          <{ name }>

        </a>
      }
    </li>
  } where {
    active =
      case (page) {
        Page::PullRequest => true
        Page::PullRequests => true
        Page::Build => true
      }
  }
}
