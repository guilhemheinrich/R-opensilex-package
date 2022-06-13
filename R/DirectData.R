#' Direct Data import
#'
#' @param host url of the hosting opensilex service
#' @param user opensilex user
#' @param password opesnielx user's password
#' @param experiment_uri uri of the targeted experiment
#' @param scientific_object_type uri of the targeted scientific object type
#'
#' @return
#' @export
#' @importFrom httr GET content add_headers
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr filter
#' @importFrom utils URLencode read.csv
#' @importFrom rlang .data
#' @examples
get_data <- function(host,
                     user,
                     password,
                     experiment_uri,
                     scientific_object_type) {
  token <- opensilexR::get_token(host, user, password)

  # Retrieve SO per type
  call1 <-
    paste(
      host,
      "/core/scientific_objects",
      "?",
      "experiment=",
      utils::URLencode(experiment_uri, reserved = TRUE),
      # Only one
      "&",
      paste0(
        "rdf_types=",
        URLencode(scientific_object_type, reserved = TRUE),
        collapse = "&"
      ),
      "&page_size=10000",
      sep = ""
    )
  get_result <- httr::GET(call1, httr::add_headers(Authorization = token))
  get_result_text <- httr::content(get_result, "text")
  get_result_json <- jsonlite::fromJSON(get_result_text, flatten = TRUE)
  so_list <- get_result_json$result

  token <- opensilexR::get_token(
    host = host,
    user = user,
    password = password
  )
  call1 <- paste0(
    host,
    "/core/data/export",
    "?experiments=",
    utils::URLencode(experiment_uri, reserved = TRUE),
    "&mode=long"
  )
  get_result <-
    httr::GET(
      call1,
      httr::add_headers(
        Authorization = token,
         `Content-Type` = "application/json")
    )
  get_result_text <- httr::content(get_result, "text")
  result_df <- utils::read.csv(text = get_result_text, header = TRUE)
  # Next not working properly, fixed following
  # https://stackoverflow.com/a/70467345
  # final_df <- result_df %>% dplyr::filter(rlang::.data$Target.URI %in% so_list$uri)
  final_df <- result_df %>% dplyr::filter(dplyr::cur_data_all()[["Target.URI"]] %in% so_list$uri)
  return(final_df)
}