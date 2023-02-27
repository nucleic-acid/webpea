#' @title webpea
#'
#' @description Saves graphs in *.webp image format.
#'
#' @param filename Filename to save the webp image to.
#' @param plot The plot to be saved.
#' @param path_return Boolean, whether the absolute output path should be returned.
#' This allows to wrap the function in another function that works with the returned image. See
#' vignette for details. By default true.
#' @param quality Integer between 1 and 100. Specifies output quality for webp format. See {magick}
#' documentation for details. Defaults to 100, as this produces smaller images as compared to {magick}'s
#' default of 75.
#' @param ggsave Not yet in use.
#' @param ... Arguments to be passed to either ggplot::ggsave() or magick::image_graph(), depending
#' on the value of the ggsave parameter.
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
#' p1 <- ggplot2::ggplot(mtcars) +
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
#' \dontrun{
#' # using {magick} graphics device
#' # draw basic plot
#' p_draw <- ggplot2::ggplot(mtcars) +
#'   ggplot2::aes(disp, hp, color = as.factor(cyl)) +
#'   ggplot2::geom_point(alpha = 0.7)
#'
#' webpea(
#'   tempfile("plot", fileext = ".webp"),
#'   plot = p_draw,
#'   ggsave = FALSE, # this switches to the {magick} graphics device
#'   width = 1920,
#'   height = 1080,
#'   res = 326,
#'   quality = 42
#' )
#' }
#'
#' @export
#' @importFrom ggplot2 ggsave
#' @importFrom magick image_read image_write
#' @importFrom grDevices dev.list dev.off


webpea <- function(filename, plot = NULL, path_return = TRUE, quality = NULL, ggsave = TRUE, ...) {
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

  if (is.null(quality)) {
    quality <- 100
  }

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
    # drop all parameters that are not suitable for magick graphics device:
    possibleOptions <- c("width", "height", "bg", "pointsize", "res", "clip", "antialias")
    paramList <- paramList[names(paramList) %in% possibleOptions]

    tryCatch(
      {
        img <- do.call(magick::image_graph, args = paramList)
        plot(plot)
        dev.off()
      },
      error = function(err) {
        message("Error when drawing plot.")
        print(err)
      },
      finally = {
        if (!is.null(dev.list())) {
          dev.off()
        }
      }
    )
    magick::image_write(img, path = filename, format = "webp", quality = quality)
  }

  if (path_return) {
    return(R.utils::getAbsolutePath(filename))
  } else {
    return(filename)
  }
}
