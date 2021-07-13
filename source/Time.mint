module Time {
  fun getTime (date : Time) : Number {
    `
    (() => {
      return #{date}.getTime()
    })()
    `
  }
}
