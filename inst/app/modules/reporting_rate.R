reportingRateUI <- function(id) {
  ns <- NS(id)

  fluidRow(
    box(
      title = 'Reporting Rate Indicators',
      status = 'success',
      width = 12,
      fluidRow(
        column(3, numericInput(ns('threshold'), label = 'Performance Threshold', value = 90)),
        column(2, offset = 7, helpButtonUI(ns('average_reporting')))
      ),
      fluidRow(
        column(12, plotOutput(ns('district_report_plot'))),
        column(3, downloadButton(ns('download_plot'), label = 'Download Plot', style = 'color:#2196F3;width:100%;margin-top:10px;')),
        column(3, downloadButton(ns('download_data'), label = 'Download Data', style = 'color:#2196F3;width:100%;margin-top:10px;'))
      )
    ),
    box(
      title = 'Districts with low reporting rate',
      width = 12,
      status = 'success',
      fluidRow(
        column(3, selectizeInput(ns('indicator'),
                                 label = 'Indicator',
                                 choices = c('ANC' = 'anc_rr', 'Institutional Delivery' = 'idelv_rr', 'Vaccination' = 'vacc_rr'))),
        column(3, selectizeInput(ns('year'),
                                 label = 'Year',
                                 choices =NULL)),
        column(12, gt_output(ns('low_reporting')))
      )
    )
  )
}

reportingRateServer <- function(id, data) {
  stopifnot(is.reactive(data))

  moduleServer(
    id = id,
    module = function(input, output, session) {

      observe({
        req(data())

        years <- data() %>% distinct(year) %>% arrange(desc(year)) %>% pull(year)

        updateSelectizeInput(session, 'year', choices = years)
      })

      district_rr <- reactive({
        req(data())

        data() %>%
          cd2030::calculate_district_reporting_rate(input$threshold)
      })

      average_rr <- reactive({
        req(data())

        data() %>%
          cd2030::calculate_average_reporting_rate()
      })

      district_low_rr <- reactive({
        req(data())

        data() %>%
          district_low_reporting(input$threshold)
      })

      output$district_report_plot <- renderPlot({
        plot(district_rr())
      })

      output$download_plot <- downloadHandler(
        filename = function() { paste0("district_rr_plot_", Sys.Date(), ".png") },
        content = function(file) {
          req(district_rr())
          par(cex = 0.4)
          plot(district_rr())

          ggsave(file, width = 1920, height = 1080, dpi = 150, units = 'px')
        }
      )

      output$download_data <- downloadHandler(
        filename = function() { paste0("checks-reporting_rate_", Sys.Date(), ".xlsx") },
        content = function(file) {

          wb <- createWorkbook()
          low_rr_national <- average_rr()
          district_rr_national <- district_rr()

          sheet_name_1 <- "Average RR by year"
          addWorksheet(wb, sheet_name_1)
          writeData(wb, sheet = sheet_name_1, x = "Table 1 - average reporting rates for all indicators, by year", startCol = 1, startRow = 1)
          writeData(wb, sheet = sheet_name_1, x = low_rr_national, startCol = 1, startRow = 3)

          # Check if sheet exists; if not, add it
          sheet_name_2 <- "RR >= threshold (districts)"
          addWorksheet(wb, sheet_name_2)
          writeData(wb, sheet = sheet_name_2, x = "Table 2 - Percentage of districts with reporting rates >= threshold, by year", startRow = 1, startCol = 1)
          writeData(wb, sheet = sheet_name_2, x = district_rr_national, startCol = 1, startRow = 3)

          # Save the workbook
          saveWorkbook(wb, file, overwrite = TRUE)
        }
      )

      output$low_reporting <- render_gt({

        district_low_rr() %>%
          filter(if_any(input$indicator, ~ .x < input$threshold), year == input$year) %>%
          gt() %>%
          fmt_number(
            columns = ends_with("_rr"), # Select columns ending with "rr"
            decimals = 1              # Format to 1 decimal place
          ) %>%
          tab_style(
            style = list(
              cell_fill(color = "lightblue"),  # Highlight with light blue background
              cell_text(weight = "bold")      # Make text bold
            ),
            locations = cells_body(columns = input$indicator) # Highlight only the "vacc_rr" column
          ) %>%
          tab_header(
            title = paste0('Districts with Reporting Rate < ', input$threshold, ' for ', input$indicator, ' in ', input$year)
          )

      })

      helpButtonServer('average_reporting', 'Reporting Rate Indicators', 'l', '2_reporting_rate.md')
    }
  )
}
