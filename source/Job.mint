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
