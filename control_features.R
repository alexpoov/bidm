# ui - sidebar

output$sidebar = renderUI({
  sidebarPanel(
    h3("Выберите от 3 до 5 онлайн курсов"),
    selectInput(
      inputId = "courses",
      label = "Список доступных онлайн-курсов",
      choices = courses_by_categories,
      size = 20,
      selected = NULL,
      selectize = FALSE
    ),
    actionButton("consider", "Добавить"),
    br(),
    br(),
    uiOutput("final_set"),
    br(),
    disabled(
      actionBttn(inputId = "final_confirm",
                 label = "Подтвердить выбор",
                 color = "success",
                 style = "fill")
    )
  )})

output$final_set = renderUI({
  selectizeInput(
    inputId = "final_set",
    label = "Проверьте выбранные курсы (вы можете удалить курсы клавишей backspace или delete)",
    choices = rv$selected_courses,
    multiple = TRUE,
    width = '100%',
    selected = rv$selected_courses,
    size = 5
  )
})

# ui - main panel

output$c_title = renderUI(HTML(input$courses))
output$c_desc = renderUI(HTML(filter(ds, title == input$courses)$description))
output$c_plan = renderUI(HTML(filter(ds, title == input$courses)$plan))

# server logic

consider_confirm = observeEvent(input$consider, {
  rv$selected_courses = append(rv$selected_courses, input$courses)
})

# final_set_updater = observeEvent(input$final_set, {
#   rv$selected_courses = input$final_set
#   if (length(rv$selected_courses)>2 && length(rv$selected_courses)<6) {
#     shinyjs::enable("final_confirm")}
#   else {shinyjs::disable("final_confirm")}
# })

