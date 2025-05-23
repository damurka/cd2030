% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/1a_checks_reporting_rate.R
\name{calculate_district_reporting_rate}
\alias{calculate_district_reporting_rate}
\title{District-Level Reporting Rates by Year}
\usage{
calculate_district_reporting_rate(.data, threshold = 90)
}
\arguments{
\item{.data}{A \code{cd_data} object containing district-level reporting rate columns.}

\item{threshold}{Numeric. Minimum acceptable reporting rate (as a percentage).
Default: 90.}
}
\value{
A tibble of class \code{cd_district_reporting_rate} with:
\itemize{
\item One row per year.
\item Columns \verb{low_<indicator>}: percentage of districts meeting the threshold.
\item \code{low_mean_rr}: mean percentage of districts meeting the threshold across
indicators.
}
}
\description{
\code{calculate_district_reporting_rate} calculates the percentage of districts that
meet or exceed a specified reporting rate threshold for each indicator, by year.
Also computes an overall yearly mean.
}
\details{
This function supports subnational data quality monitoring by identifying the
proportion of districts with sufficiently complete reporting. It enables
year-over-year comparisons and helps target underperforming regions.
}
\examples{
\dontrun{
  # Calculate district-level reporting rates with a threshold of 90\%
  district_summary <- calculate_district_reporting_rate(data, threshold = 90)
}

}
