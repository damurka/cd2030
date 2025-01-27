% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculate_indicator_threshold_coverage.R
\name{calculate_dropout}
\alias{calculate_dropout}
\title{Calculate Dropout Coverage for Health Indicators Below a Threshold}
\usage{
calculate_dropout(
  .data,
  indicator = c("zerodose", "undervax", "dropout_penta13", "dropout_measles12",
    "dropout_penta3mcv1", "dropout_penta1mcv1"),
  source = c("dhis2", "anc1", "penta1")
)
}
\arguments{
\item{.data}{A data frame or tibble containing health indicator data, with coverage columns
named in the format \verb{cov_<indicator>_<source>}.}

\item{indicator}{Character. The specific health indicator to evaluate. Options are:
\itemize{
\item \code{"zerodose"}: Zero-dose vaccination rate.
\item \code{"undervax"}: Under-vaccination rate.
\item \code{"dropout_penta13"}: Dropout rate from Penta-1 to Penta-3.
\item \code{"dropout_measles12"}: Dropout rate from Measles-1 to Measles-2.
\item \code{"dropout_penta3mcv1"}: Dropout rate from Penta-3 to MCV-1.
\item \code{"dropout_penta1mcv1"}: Dropout rate from Penta-1 to MCV-1.
}}

\item{source}{Character. The data source for the indicator. Options are:
\itemize{
\item \code{"dhis2"}: Data from DHIS-2.
\item \code{"anc1"}: Data from ANC-1 surveys.
\item \code{"penta1"}: Data from Penta-1 surveys.
}}
}
\value{
A tibble with the selected administrative level and coverage value for regions
that do not meet the below-10\% threshold for the specified indicator and year. If no regions
meet the criteria, a default row is returned with "None" and 0 as values.
}
\description{
This function filters health indicator data to identify the percentage of administrative
regions where the coverage for a specified indicator falls below a 10\% threshold for a given year.
If no regions meet the criteria (i.e., all values are below the threshold), a default output is returned.
}
\details{
The function performs the following steps:
\enumerate{
\item \strong{Validate Inputs}: Ensures that \code{filter_year}, \code{indicator}, and \code{source} are specified correctly.
\item \strong{Determine Admin Level}: Uses the attribute \code{admin_level} of \code{.data} to identify the appropriate
administrative level for filtering (\code{adminlevel_1} or \code{district}).
\item \strong{Filter Data Below Threshold}: Creates a binary variable \code{below10} to indicate whether the
coverage is below 10\%. It then filters to keep only rows with \code{below10 == 0} and for the specified \code{filter_year}.
\item \strong{Handle No-Data Case}: If no rows meet the filtering criteria, the function returns a default row with
"None" in the admin level column and 0 in the indicator column.
}
}
\examples{
\dontrun{
# Example usage:
result <- calculate_dropout(data, filter_year = 2023, indicator = "zerodose", source = "dhis2")
print(result)
}

}
