#' Works by Vladimir Ilyich Ulyanov
#'
#' All works written by Lenin available on leninism.su
#'
#' The text is stored as a data frame with five columns. Each row corresponds
#' to a section break in the eBook. Some rows therefore have multiple documents
#' (letters, telegrams, etc) while other rows may contain only a single
#' footnote.
#'
#' There is ample metadata about Lenin's works provided in this data frame. To
#' include only works written by Lenin, filter for rows where
#' `leninru$section == "main"`.
#'
#' @format A data frame, containing five columns:
#' \describe{
#'   \item{vol}{
#'     Volume number of complete works. (Number between 1 and 55)
#'   }
#'   \item{doc_number}{Integer indicating location of document within volume}
#'   \item{year}{
#'     Year of publication. For some volumes, publication year was not
#'     clearly indicated for each document, and so for cases where the year
#'     was not clear, the year is NA
#'   }
#'   \item{section}{
#'     Annotation indicating the type of text in that row, one of:
#'     \itemize{
#'     \item{titlepage}
#'     \item{frontmatter: Forwards and other context provided by the publisher}
#'     \item{sectionstart: Indicates a new year or other text divider}
#'     \item{main: Main text, written by Lenin}
#'     \item{footnotes}
#'     \item{endnote: Additional context about the works assembled in that
#'     volume, such as descriptions of people mentioned, provided by publisher
#'     }
#'   }}
#'   \item{text}{
#'     Text, paragraph form.
#'   }
#' }
#' @source \url{https://leninism.su/works}
"leninru"

#' Titles & descriptions of Lenin's Collected Works
#'
#' All works written by Lenin available on leninism.su
#'
#' The text is stored as a data frame with two columns. Each row corresponds to
#' one of 55 volumes, and provides the title of the volume and a description of
#' the volume written by the publisher.
#'
#'
#' @format A data frame, containing three columns:
#' \describe{
#'   \item{vol}{
#'     Volume number of complete works. (Number between 1 and 55)
#'   }
#'   \item{title}{Title of volume}
#'   \item{description}{
#'     Description of works within the volume and time periods covered.
#'   }
#' }
#' @source \url{https://leninism.su/works}
"leninru_volumes"
