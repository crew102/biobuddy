store_logs <- function(logs) {
  sid <- unlist(logs$session)
  sid <- logs$session[["sessionid"]]
  user <- logs$session[["user"]]
  path <- paste0("logs/", user, "-", sid, ".json")
  if (is_local()) {
    write_json(logs, here::here(path))
  } else {
    write_s3_file(
      obj = logs,
      write_fun = write_json,
      remote_path = path
    )
  }
}
