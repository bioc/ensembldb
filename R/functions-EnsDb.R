## Functions related to EnsDb objects.

#' @title Globally filter an EnsDb database
#'
#' @description \code{.addFilter} globally filters the provided
#'     \code{EnsDb} database, i.e. it returns a \code{EnsDb} object with the
#'     provided filter permanently set and active.
#'
#' @details Adding a filter to an \code{EnsDb} object causes this filter to be
#'     permanently active. The filter will be used for all queries to the
#'     databases and is added to all additional filters passed to the methods.
#' 
#' @param x An \code{EnsDb} object on which the filter(s) should be set.
#'
#' @param filter An \code{\link[AnnotationFilter]{AnnotationFilterList}},
#'     \code{\link[AnnotationFulter]{AnnotationFilter}} object or a filter
#'     expression providing the filter(s) to be set.
#'
#' @return For \code{.addFilter}: the \code{EnsDb} object with the filter
#'     globally added and enabled.
#'
#'     For \code{.dropFilter}: the \code{EnsDb} object with all filters removed.
#'
#'     For \code{.activeFilter}: an \code{}
#'
#' @author Johannes Rainer
#'
#' @noRd
.addFilter <- function(x, filter = AnnotationFilterList()) {
    if (length(filter) == 0)
        stop("No filter provided")
    filter <- .processFilterParam(filter, x)
    ## Now, if there was no error, filter is an AnnotationFilterList
    got_filter <- getProperty(x, "FILTER")
    if (!is.na(got_filter)) {
        if (!(is(got_filter, "AnnotationFilter") |
              is(got_filter, "AnnotationFilterList")))
            stop("Globally set filter is not an 'AnnotationFilter' or ",
                 "'AnnotationFilterList'")
        filter <- AnnotationFilterList(got_filter, filter)
    }
    ## Now, what is with multiple encapsuled filters?
    setProperty(x, FILTER = filter)
}

#' @description \code{.dropFilter} drops all (globally) added filters from the
#'     submitted \code{EnsDb} object.
#'
#' @noRd
.dropFilter <- function(x) {
    dropProperty(x, "FILTER")
}

#' @description \code{.activeFilter} lists the globally set and active filter(s)
#'     of an \code{EnsDb} object.
#'
#' @noRd
.activeFilter <- function(x) {
    getProperty(x, "FILTER")
}