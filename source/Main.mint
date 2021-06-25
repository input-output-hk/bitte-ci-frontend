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

enum Page {
  PullRequests
  PullRequest(Number)
  Build(String)
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

module Time {
  fun getTime (date : Time) : Number {
    `
    (() => {
      return #{date}.getTime()
    })()
    `
  }
}

record Job {
  id : String,
  createdAt : Time using "created_at",
  updatedAt : Time using "updated_at",
  step : String,
  avatar : String,
  login : String,
  senderUrl : String using "sender_url",
  headLabel : String using "head_label",
  headRef : String using "head_ref"
}

// record Msg {

// type : String

// }

// record MsgHeader {

// type : String

// }

// record MsgJob {

// job : Job

// }

// record MsgJobs {

// jobs : Array(Job)

// }

// record MsgProjects {

// projects : Array(Project)

// }

// record Project {

// name : String,

// count : Number

// }
