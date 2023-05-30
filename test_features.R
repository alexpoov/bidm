# additional init settings
observe({
  hide(selector = ".test")
  show("add_description")
  show(paste0("step", rv$step))
  })

# ui - sidebar

output$sidebar = renderUI({
  sidebarPanel(
    # if test version - step 1
    div(
      class = "test",
      id = "step1",
      h3("Шаг 1: составьте сет рассмотрения"),
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
      uiOutput("consideration_set"),
      # https://stackoverflow.com/questions/38211490/adding-tooltip-to-disabled-button-in-shiny
      disabled(actionBttn(inputId = "consider_confirm",
                 label = "Подтвердить сет",
                 style = "fill"))
    ),
    
    # if test version - step 2
    hidden(div(
      class = "test",
      id = "step2",
      h3("Шаг 2: выберите финальный список курсов"),
      uiOutput("courses_2"),
      actionButton("choose", "Выбрать"),
      br(),
      br(),
      uiOutput("final_set"),
      # сделать тултип для кнопки
      # https://stackoverflow.com/questions/38211490/adding-tooltip-to-disabled-button-in-shiny
      actionButton(inputId = "back",
                   label = "< Назад"),
      
      br(),
      br(),
      disabled(
        actionBttn(inputId = "final_confirm",
                   label = "Подтвердить выбор",
                   color = "success",
                   style = "fill")
      )
    ))
  )})

output$consideration_set = renderUI({
  selectizeInput(
    inputId = "consideration_set",
    label = "Проверьте сет рассмотрения (вы можете удалить курсы клавишей backspace или delete)",
    choices = rv$selected_courses,
    multiple = TRUE,
    width = '100%',
    selected = rv$selected_courses,
    size = 5
  )
})

output$courses_2 = renderUI({
  selectInput(
    inputId = "courses_2",
    label = "Ваш сет рассмотрения:",
    choices = rv$consideration_set,
    size = 10,
    selected = NULL,
    selectize = FALSE
  )})

output$final_set = renderUI({
  selectizeInput(
    inputId = "final_set",
    label = "Перепроверьте курсы, на которые вы хотите податься (от 3 до 5):",
    choices = rv$selected_courses,
    multiple = TRUE,
    width = '100%',
    selected = rv$selected_courses,
    size = 5
  )
})

observeEvent(input$final_set, {
  rv$selected_courses = input$final_set
})

#  ui - main panel

output$c_title = renderUI(HTML(ifelse(rv$step == 1, input$courses, input$courses_2)))
output$c_desc = renderUI(HTML(ifelse(rv$step == 1, filter(ds, title == input$courses)$description, filter(ds, title == input$courses_2)$description)))
output$c_plan = renderUI(HTML(ifelse(rv$step == 1, filter(ds, title == input$courses)$plan, filter(ds, title == input$courses_2)$plan)))

#  server

navPage <- function(direction) {
  rv$step <- rv$step + direction }

observeEvent(input$consider, {
  rv$selected_courses = append(rv$selected_courses, input$courses)})

observeEvent(input$consideration_set, {
  rv$selected_courses = input$consideration_set
  if (length(rv$selected_courses)>2) {
    shinyjs::enable("consider_confirm")}
  else {disable("consider_confirm")}
})

break_popup = observeEvent(input$consider_confirm, {
  navPage(1)
  sendSweetAlert(
    session = session,
    title = "Сделайте перерыв",
    text = "Чаще всего выбор образовательных траекторий занимает продолжительное время для обдумывания. Поэтому просим вас отвлечься от эксперимента минимум на  на 2-3 минуты, это увеличит переносимость результатов на реальные сценарии. Нажмите кнопку снизу, когда будете готовы продолжить.",
    type = "info"
  )
  rv$user_logs = rbind(rv$user_logs, list(as.character(.POSIXct(Sys.time(), tz = "CET")), version, "consideration_set", paste(input$consideration_set, collapse = '; ')))
  rv$consideration_set = rv$selected_courses
  rv$selected_courses = list()
})

back_button = observeEvent(input$back,{
  navPage(-1)
  rv$selected_courses = rv$consideration_set
})

observeEvent(input$choose, {
  rv$selected_courses = append(rv$selected_courses, input$courses_2)
  if (length(rv$final_courses)>2 && length(rv$final_courses)<6) {
    shinyjs::enable("final_confirm")}
  else {shinyjs::disable("final_confirm")}
})


