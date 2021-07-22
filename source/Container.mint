component Container {
  connect Application exposing { error }

  property title : String
  property children : Array(Html) = []

  fun render : Html {
    <div class="container">
      <div class="mt-3 mb-3 d-flex">
        <div class="me-auto">
          <h2>
            <{ title }>
          </h2>
        </div>
      </div>

      <If condition={Maybe.isJust(error)}>
        <pre>
          <{ error or "" }>
        </pre>
      </If>

      <{ children }>
    </div>
  }
}
