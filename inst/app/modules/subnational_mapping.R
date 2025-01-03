subnationalMappingUI <- function(id) {
  ns <- NS(id)

  tagList(
    contentHeader(ns('mapping'), 'Mapping'),
    contentBody(
      box(
        title = 'Analysis Options',
        status = 'success',
        width = 12,
        solidHeader = TRUE,
        fluidRow(
          column(3, selectizeInput(ns('level'), label = 'Subnational Level',
                                   choices = c('Admin Level 1' = 'adminlevel_1',
                                               'District' = 'district'))),
          column(3, selectizeInput(ns('denominator'), label = 'Denominator',
                                   choices = c('DHIS2' = 'dhis2',
                                               'ANC 1' = 'anc1',
                                               'Penta 1' = 'penta1'))),
          column(3, selectizeInput(ns('palette'), label = 'Palette', choices = NULL))
        )
      ),

      tabBox(
        id = ns('coverage'),
        title = 'Coverage/Utilization Level',
        width = 12,

        tabPanel(
          'Penta 3 Coverage',
          fluidRow(
            column(12, plotCustomOutput(ns('penta3_coverage'))),
            column(3, downloadButtonUI(ns('penta3_download'))),
          )
        ),

        tabPanel(
          'Measles 1 Coverage',
          fluidRow(
            column(12, plotCustomOutput(ns('mcv1_coverage'))),
            column(3, downloadButtonUI(ns('mcv1_download'))),
          )
        ),

        tabPanel(
          'Penta1 - Penta3 dropout',
          fluidRow(
            column(12, plotCustomOutput(ns('penta13_dropout'))),
            column(3, downloadButtonUI(ns('penta13_dropout_download'))),
          )
        ),

        tabPanel(
          'Penta3 - MCV3 dropout',
          fluidRow(
            column(12, plotCustomOutput(ns('penta3mcv1_dropout'))),
            column(3, downloadButtonUI(ns('penta3mcv1_droput_download'))),
          )
        ),

        tabPanel(
          'Custom Check',
          fluidRow(
            column(3, selectizeInput(ns('indicator'), label = 'Indicator',
                                     choices = c('Select' = '0', "anc1", "bcg", "measles2", "measles3", "opv1", "opv2", "opv3",
                                                 "pcv1", "pcv2", "pcv3", "penta1", "penta2", "rota1", "rota2", "instdeliveries",
                                                 "ipv1", "ipv2", "undervax", "zerodose", "dropout_measles12")))
          ),
          fluidRow(
            column(12, plotCustomOutput(ns('custom'))),
            column(3, downloadButtonUI(ns('custom_download'))),
          )
        )
      )
    )
  )
}

subnationalMappingServer <- function(id, cache) {
  stopifnot(is.reactive(cache))

  moduleServer(
    id = id,
    module = function(input, output, session) {

      data <- reactive({
        req(cache())
        cache()$get_adjusted_data()
      })

      country <- reactive({
        req(cache())
        cache()$get_country()
      })

      un_estimates <- reactive({
        req(cache())
        cache()$get_un_estimates()
      })

      subnational_map <- reactive({
        req(cache())
        cache()$get_map_mapping()
      })

      dt <- reactive({
        req(data(), un_estimates(), input$denominator, input$palette)

        data() %>%
          get_mapping_data(un_estimates(), cache()$get_national_estimates(), subnational_map())
      })

      observe({
        req(input$coverage, input$indicator)

        palette <- if (grepl('drop', input$coverage)) {
          c("Reds", "Purples")
        } else if (grepl('Coverage', input$coverage)) {
          c("Greens", "Blues")
        } else {
          if (grepl('drop|under|zero', input$indicator)) {
            c("Reds", "Purples")
          } else {
            c("Greens", "Blues")
          }
        }

        updateSelectizeInput(session, 'palette', choices = palette)
      })

      output$penta13_dropout <- renderCustomPlot({
        req(dt())

        title <- paste("Distribution of Penta1 to Penta3 dropout in ", country(), "by Regions")
        plot(dt(), indicator = 'dropout_penta13',
             denominator = input$denominator,
             palette = input$palette,
             title = title)
      })

      output$penta3mcv1_dropout <- renderCustomPlot({
        req(dt())

        title <- paste("Distribution of Penta1 to Measles3 dropout in ", country(), "by Regions")
        plot(dt(), indicator = 'dropout_penta3mcv1',
             denominator = input$denominator,
             palette = input$palette,
             title = title)
      })

      output$penta3_coverage <- renderCustomPlot({
        req(dt())

        title <- paste("Distribution of Penta3 Coverage in ", country(), "by Regions")
        plot(dt(), indicator = 'penta3',
             denominator = input$denominator,
             palette = input$palette,
             title = title)
      })


      output$mcv1_coverage <- renderCustomPlot({
        req(dt())

        title <- paste("Distribution of Measles 1 Coverage in ", country(), "by Regions")
        plot(dt(), indicator = 'measles1',
             denominator = input$denominator,
             palette = input$palette,
             title = title)
      })

      output$custom <- renderCustomPlot({
        req(dt(), input$indicator != '0')

        title <- paste('Distribution of ', input$indicator,' Coverage in ', country(), 'by Regions')
        plot(dt(), indicator = input$indicator,
             denominator = input$denominator,
             palette = input$palette,
             title = title)
      })

      downloadPlot(
        id = 'penta3_download',
        filename = paste0('penta3_', input$level, '_map_', input$denominator),
        data = dt,
        plot_function = function() {
          plot(dt(), indicator = 'penta3',
               denominator = input$denominator,
               palette = input$palette,
               title = paste("Distribution of Penta3 Coverage in ", country(), "by Regions"))
        }
      )

      downloadPlot(
        id = 'mcv1_download',
        filename = paste0('mcv1_', input$level, '_map_', input$denominator),
        data = dt,
        plot_function = function() {
          plot(dt(), indicator = 'measles1',
               denominator = input$denominator,
               palette = input$palette,
               title = paste("Distribution of Measles 1 Coverage in ", country(), "by Regions"))
        }
      )

      downloadPlot(
        id = 'penta13_dropout_download',
        filename = paste0('penta13_dropout_', input$level, '_map_', input$denominator),
        data = dt,
        plot_function = function() {
          plot(dt(), indicator = 'dropout_penta13',
               denominator = input$denominator,
               palette = input$palette,
               title = paste("Distribution of Penta1 to Penta3 dropout Coverage in ", country(), "by Regions"))
        }
      )

      downloadPlot(
        id = 'penta3mcv1_droput_download',
        filename = paste0('penta3mcv1_droput_', input$level, '_map_', input$denominator),
        data = dt,
        plot_function = function() {
          plot(dt(), indicator = 'dropout_penta3mcv1',
               denominator = input$denominator,
               palette = input$palette,
               title = paste("Distribution of Penta1 to Measles3 dropout in ", country(), "by Regions"))
        }
      )

      downloadPlot(
        id = 'custom_download',
        filename = paste0(input$indicator, '_', input$level, '_map_', input$denominator),
        data = dt,
        plot_function = function() {
          plot(dt(), indicator = input$indicator,
               denominator = input$denominator,
               palette = input$palette,
               title = paste('Distribution of ', input$indicator,' Coverage in ', country(), 'by Regions'))
        }
      )

      contentHeaderServer(
        'mapping',
        md_title = 'Mapping',
        md_file = '2_reporting_rate.md'
      )
    }
  )
}
