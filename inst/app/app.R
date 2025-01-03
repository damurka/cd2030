# increase the uploading file size limit to 2000M, now our upload is not just about hfd file, it also include the saved data.
options(shiny.maxRequestSize = 2000*1024^2)
# options(shiny.trace = TRUE)
# options(shiny.trace = FALSE)

library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(shinyFiles)
library(cd2030)
library(cli)
library(dplyr)
# library(echarts4r)
library(gt)
library(DT)
library(openxlsx)
library(khisr)
library(plotly)
library(purrr)
library(forcats)
library(lubridate)
library(RColorBrewer)
library(tidyr)
library(sf)
library(shinyjs)
library(stringr)

source('logic/survey_helper.R')
source('modules/help_button.R')
source('modules/introduction.R')
source('modules/setup.R')
source('modules/upload_data.R')
source('modules/reporting_rate.R')
source('modules/data_completeness.R')
source('modules/consistency_check.R')
source('modules/outlier_detection.R')
source('modules/calculate_ratios.R')
source('modules/overall_score.R')
source('modules/remove_years.R')
source('modules/data_adjustment.R')
source('modules/denominator_assessment.R')
source('modules/denominator_selection.R')
source('modules/national_coverage.R')
source('modules/subnational_coverage.R')
source('modules/subnational_inequality.R')
source('modules/subnational_mapping.R')
source('modules/equity.R')
source('modules/download/download_button.R')
source('modules/download/download_coverage.R')
source('modules/download/download_helper.R')
source('modules/download/download_report.R')
source('modules/adjustment_changes.R')
source('modules/documentation_button.R')
source('modules/content_header.R')
source('modules/content_body.R')
source('modules/message_box.R')
source('modules/render-plot.R')

ui <- dashboardPage(
  skin = 'green',
  header = dashboardHeader(title = 'cd2030'),
  sidebar = dashboardSidebar(
    sidebarMenu(
      id = 'tabs',
      menuItem('Introduction', tabName = 'introduction', icon = icon('info-circle')),
      menuItem('Load Data', tabName = 'upload_data', icon = icon('upload')),
      menuItem('Quality Checks',
               tabName = 'quality_checks',
               icon = icon('check-circle'),
               startExpanded  = TRUE,
               menuSubItem('Reporting Rate',
                           tabName = 'reporting_rate',
                           icon = icon('chart-bar')),
               menuSubItem('Outlier Detection',
                           tabName = 'outlier_detection',
                           icon = icon('exclamation-triangle')),
               menuSubItem('Consistency Check',
                           tabName = 'consistency_check',
                           icon = icon('tasks')),
               menuSubItem('Data Completeness',
                           tabName = 'data_completeness',
                           icon = icon('check-square')),
               menuSubItem('Calculate Ratios',
                           tabName = 'calculate_ratios',
                           icon = icon('percent')),
               menuSubItem('Overall Score',
                           tabName = 'overall_score',
                           icon = icon('star'))
               ),
      menuItem('Remove Years', tabName = 'remove_years', icon = icon('trash')),
      menuItem('Data Adjustment', tabName = 'data_adjustment', icon = icon('adjust')),
      menuItem('Data Adjustment Changes', tabName = 'data_adjustment_changes', icon = icon('adjust')),
      menuItem('Analysis Setup', tabName = 'setup', icon = icon('sliders-h')),
      menuItem('Denominator Selection',
               tabName = 'denom_assess',
               icon = icon('calculator'),
               menuSubItem('Denominator Assessment',
                           tabName = 'denominator_assessment',
                           icon = icon('calculator')),
               menuSubItem('Denominator Selection',
                           tabName = 'denominator_selection',
                           icon = icon('filter'))
               ),
      menuItem('National Analysis',
               tabName = 'national_analysis',
               icon = icon('flag'),
               menuSubItem('National Coverage',
                           tabName = 'national_coverage',
                           icon = icon('map-marked-alt'))
               ),
      menuItem('Subnational Analysis',
               tabName = 'subnational_analysis',
               icon = icon('flag'),
               menuSubItem('Subational Coverage',
                           tabName = 'subnational_coverage',
                           icon = icon('map-marked')),
               menuSubItem('Sub-National Inequality',
                           tabName = 'subnational_inequality',
                           icon = icon('balance-scale-right')),
               menuSubItem('Sub-National Mapping',
                           tabName = 'subnational_mapping',
                           icon = icon('map'))
               ),
      menuItem('Equity Assessment', tabName = 'equity_assessment', icon = icon('balance-scale'))
    )
  ),
  body = dashboardBody(
    useShinyjs(),
    tags$head(
      tags$link(rel = 'stylesheet', type = 'text/css', href = 'styles.css'),
      tags$link(rel = 'stylesheet', type = 'text/css', href = 'rmd-styles.css')
    ),
    tabItems(
      tabItem(tabName = 'introduction', introductionUI('introduction')),
      tabItem(tabName = 'upload_data', uploadDataUI('upload_data')),
      tabItem(tabName = 'reporting_rate', reportingRateUI('reporting_rate')),
      tabItem(tabName = 'data_completeness', dataCompletenessUI('data_completeness')),
      tabItem(tabName = 'consistency_check', consistencyCheckUI('consistency_check')),
      tabItem(tabName = 'outlier_detection', outlierDetectionUI('outlier_detection')),
      tabItem(tabName = 'calculate_ratios', calculateRatiosUI('calculate_ratios')),
      tabItem(tabName = 'overall_score', overallScoreUI('overall_score')),
      tabItem(tabName = 'remove_years', removeYearsUI('remove_years')),
      tabItem(tabName = 'data_adjustment', dataAjustmentUI('data_adjustment')),
      tabItem(tabName = 'data_adjustment_changes', adjustmentChangesUI('data_adjustment_changes')),
      tabItem(tabName = 'setup', setupUI('setup')),
      tabItem(tabName = 'denominator_assessment', denominatorAssessmentUI('denominator_assessment')),
      tabItem(tabName = 'denominator_selection', denominatorSelectionUI('denominator_selection')),
      tabItem(tabName = 'national_coverage', nationalCoverageUI('national_coverage')),
      tabItem(tabName = 'subnational_coverage', subnationalCoverageUI('subnational_coverage')),
      tabItem(tabName = 'subnational_inequality', subnationalInequalityUI('subnational_inequality')),
      tabItem(tabName = 'subnational_mapping', subnationalMappingUI('subnational_mapping')),
      tabItem(tabName = 'equity_assessment', equityUI('equity_assessment'))
    )
  )
)

server <- function(input, output, session) {

  cache <- reactiveVal()

  introductionServer('introduction')
  data <- uploadDataServer('upload_data')
  observeEvent(data(), {
    req(data())

    cache_instance <- init_CacheConnection(countdown_data = data())$reactive()
    cache(cache_instance())

    shinyjs::delay(500, {
      country <- cache()$get_country()
      updateHeader(country)
      shinyjs::addClass(selector = 'body', class = 'fixed')
    })
  })

  reportingRateServer('reporting_rate', cache)
  dataCompletenessServer('data_completeness', cache)
  consistencyCheckServer('consistency_check', cache)
  outlierDetectionServer('outlier_detection', cache)
  calculateRatiosServer('calculate_ratios', cache)
  overallScoreServer('overall_score', cache)
  removeYearsServer('remove_years', cache)
  dataAdjustmentServer('data_adjustment', cache)
  adjustmentChangesServer('data_adjustment_changes', cache)
  setupServer('setup', cache)
  denominatorAssessmentServer('denominator_assessment', cache)
  denominatorSelectionServer('denominator_selection', cache)
  nationalCoverageServer('national_coverage', cache)
  subnationalCoverageServer('subnational_coverage', cache)
  subnationalInequalityServer('subnational_inequality', cache)
  subnationalMappingServer('subnational_mapping', cache)
  equityServer('equity_assessment', cache)
  downloadReportServer('download_report', cache)

  updateHeader <- function(country) {
    header_title <- div(
      class = 'navbar-header',
      h4(HTML(paste0(country, ' &mdash; Countdown Analysis')), class = 'navbar-brand')
    )

    # Dynamically update the header
    header <- htmltools::tagQuery(
      dashboardHeader(
        title = 'cd2030',
        tags$li(class = 'dropdown', downloadReportUI('download_report'))
      )
    )
    header <- header$
      find('.navbar.navbar-static-top')$      # find the header right side
      append(header_title)$                     # inject dynamic content
      allTags()

    removeUI(selector = 'header.main-header', immediate = TRUE)

    # Replace the header in the UI
    insertUI(
      selector = 'body',
      where = 'afterBegin',
      ui = header
    )
  }
}

shinyApp(ui = ui, server = server)
