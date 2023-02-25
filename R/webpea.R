#' @title webpea
#'
#' @description Saves graphs in *.webp image format.
#'
#' @param filename Filename to save the webp image to.
#' @param path_return Boolean, whether the absolute output path should be returned.
#' This allows to wrap the function in another function that works with the returned image. See
#' vignette for details. By default true.
#' @param quality Integer between 1 and 100. Specifies output quality for webp format. See {magick}
#' documentation for details. Defaults to reasonable 75, when not given.
#' @param ggsave Not yet in use.
#' @param ... Arguments to be passed to ggplot::ggsave()
#'
#'
#' @return Filename or path to the saved webp image.
#'
#' @examples
#'
#' # save last plot with default ggsave settings
#'
#' ggplot2::ggplot(mtcars) +
#'   ggplot2::aes(disp, hp, color = cyl) +
#'   ggplot2::geom_point(alpha = 0.1)
#'
#' webpea(tempfile("plot", fileext = ".webp"))
#'
#' # save specific plot with optional ggsave paramaters and in higher-than-default quality
#'
#' p1 <- ggplot2::ggplot(mtcars, ) +
#'   ggplot2::aes(disp, hp, color = cyl) +
#'   ggplot2::geom_point(alpha = 0.4)
#'
#' webpea(
#'   tempfile("plot", fileext = ".webp"),
#'   plot = p1,
#'   width = 16,
#'   height = 9,
#'   quality = 90
#' )
#'
#' @export
#' @importFrom ggplot2 ggsave
#' @importFrom magick image_read image_write


webpea <- function(filename, path_return = TRUE, quality = NULL, ggsave = TRUE, ...) {
  # check requirements
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is needed to use this function. Install ggplot2 via install.packages('ggplot2').")
  }

  if (!requireNamespace("magick", quietly = TRUE)) {
    stop("magick is needed to use this function. Install magick via install.packages('magick').")
  }

  # check inputs
  stopifnot(is.character(filename) & !is.null(filename))
  stopifnot(is.logical(path_return))
  stopifnot(is.logical(ggsave))
  stopifnot(is.null(quality) | is.numeric(quality))
  stopifnot(quality > 0 & quality <= 100)

  paramList <- list(...)

  intermediate_file <- tempfile("intermediate", fileext = ".png")

  paramList$filename <- intermediate_file

  if (ggsave) {
    # save plot to temporary directory
    tryCatch(
      {
        suppressMessages(
          do.call(
            ggplot2::ggsave,
            paramList
          )
        )

      },
      error = function(err) {
        message("PNG not created.")
        print(err)
      }
    )

    # read intermediate plot with magick
    intermediate_img <- magick::image_read(intermediate_file)

    # write intermediate file in webp format
    magick::image_write(
      path = filename,
      intermediate_img,
      format = "webp",
      quality = quality
    )
  } else {
    message("Direct export via magick graphic device is not yet supported.")
  }

  if (path_return) {
    return(R.utils::getAbsolutePath(filename))
  } else {
    return(filename)
  }
}
