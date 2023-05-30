library(shiny)
library(aws.s3)
library(readr)
library(dplyr)
library(shinyjs)
library(stringr)
library(jsonlite)
library(mongolite)
library(shinythemes)
library(shinyWidgets)
source('files/decide_version.R', local = TRUE) # MAB
source('files/secret.R', local = TRUE) # keys

# ################################################

ui <- fluidPage(
  
  theme = shinytheme("lumen"),
  shinyjs::useShinyjs(),
  useSweetAlert(),
                
  navbarPage(
    
    "Эксперимент",
    id = "exp",
             
       # page1
       tabPanel("Описание Эксперимента", 
                value = "tab1",
                fluid = TRUE,
                sidebarLayout(
                  titlePanel("Эксперимент Образовательного Выбора [Толока]"),
                  mainPanel(
                    HTML('<br> Привет! <br><br> Меня зовут Саша, и я заканчиваю магистратуру. В рамках своей дипломной работы я провожу эксперимент по изучению принятия решений в образовательном выборе. Его итоги помогут лучше понять, на что студенты обращают внимание при поступлении в ВУЗы или выборе элективов. Ваши ответы будут очень важны для создания платформ выбора курсов. Для этого, пожалуйста, отнеситесь к прохождению эксперимента внимательно и бережно :-)'),
                    br(),
                    h3('Ситуация'),
                    HTML('Представьте, что на работе вам согласовали выплаты для прохождения онлайн-курсов на платформе “Ягодка”. Вы можете выбрать от 3 до 5 онлайн-курсов как по вашей специализации, так и ради расширения кругозора. <br><br> <strong>Важно:</strong> сменить выбор после отправки заявки будет нельзя. Внимательно прочитайте описания курсов и их учебный план, чтобы выбрать лучшие для вас.'),
                    br(),
                    hidden(div(
                      id = "add_description",
                      h3('Стратегия выбора'),
                      HTML('В качестве помощи при выборе платформа предлагает вам воспользоваться теорией составления сетов рассмотрения, т.е. подойти к выбору как к постепенному отбору. Эта теория перекочевала из маркетинговых исследований в область психологии принятия решений. Состоит их трёх основных этапов: <ul><li>Осознание, или осведомлённость - набор, в которые попадают те альтернативы, о которых человек осведомлён. Он может состоять как из всез доступных вариантов для выбора, так и не включать в себя те, которые были пропущены (например случайно);</li><li>Рассмотрение - набор предварительно отобранных наиболее интересующих курсов. Для его формирования человек не тратит много времени, как бы набрасывая список привлекательных альтернатив;</li><li>Решение, или оценка - финальное сравнение и выбор наиболее подходящих опций.</li></ul>'),
                      br(),
                      img(src='choice_sets.png', align = "left", width="100%"),
                      br(),
                      h3('Инструкция к выполнению эксперимента'),
                      HTML('Во вкладке “Выбор Курсов” вам будет предложено выбрать онлайн-курсы. Процесс будет состоять из двух шагов: <ul><li>Шаг 1: составление сета рассмотрения. Изучите онлайн-курсы и накидайте примерный список интересующих вас опций;</li><li>Шаг 2: Формирование окончательного выбора. Проанализируйте понравившееся вам курсы и оставьте только те, которые вы хотите утвердить как выбранные.</li></ul>'),
                      br(),
                      HTML("Для правдоподобности эксперимента возьмите перерыв 2-3 минуты между шагами выбора курсов"),
                      br()
                    )),
                    br(),
                    HTML("После утверждения выбора вы будете перенаправлены на вкладку “Оцените Свой Выбор” и получите код подтверждения для Толоки после ответа на 4 коротких вопроса."),
                    br(),
                    br(),
                    HTML("Успехов!"),
                    br(),
                    br(),
                    actionBttn(
                      inputId = "start",
                      label = "Начать выбор курсов",
                      style = "jelly"
                    ),
                    br(),
                    br()
                  ))),

       # page2
       tabPanel("Выбор Курсов",
                value = "tab2",
                fluid = TRUE,
                sidebarLayout(
                  uiOutput("sidebar"),
                  mainPanel(
                    h2(htmlOutput("c_title")),
                    p(strong("Описание")),
                    p(htmlOutput("c_desc")),
                    p(strong("Учебный план")),
                    p(htmlOutput("c_plan"))
                  ))),


       # page3
       tabPanel("Оцените Свой Выбор",
                value = "tab3",
                fluid = TRUE,
                sidebarLayout(
                  titlePanel("Оцените использование сервиса"),
                  mainPanel(
                    hidden(div(
                      class = "evalpage",
                      id = "evaluation",
                      HTML("В завершение эксперимента вам будет предложено оценить ваш выбор. Используйте слайдеры под вопросами, чтобы оценивать степень согласия с утверждением (1 - полностью не согласен, 5 - полностью согласен)"),
                      br(),
                      br(),
                      sliderInput("awareness",
                                  "Вы уверены, что ваш выбор лучше всего соответствует вашим предпочтениям?",
                                  min = 1, max = 5, value = 3),
                      # такой вопрос лучше всего оценить отдельно по каждому курсу и взять среднее, но это advanced
                      sliderInput("engagement",
                                  "Вы хотели бы пройти выбранные вами курсы целиком, так как считаете их полезными/интересными?",
                                  min = 1, max = 5, value = 3
                      ),
                      sliderInput("transparency",
                                  "Платформа (интерфейс и процесс выбора, без материалов курсов) была вам понятна и полезна для выбора подходящих вам курсов?",
                                  min = 1, max = 5, value = 3
                      ),
                      textInput("caption", "Пожалуйста, используйте это поле, чтобы оставить свой отзыв или любые комментарии по вопросам выше", ""),
                      br(),
                      actionBttn("subm", "Подтвердить заявку"),
                      br()
                    )),
                    div(
                      class = "evalpage",
                      id = "plug",
                      HTML("Для перехода к оцениванию и получению кода завершения эксперимента, пожалуйста, завершите этап выбора курсов (2ая вкладка)")
                    )
                  )))
                ))

# ################################################

server <- function(input, output, session) {
  
  # before your very eyes
  version = decideAppVersion()
  
  rv = reactiveValues(
    step = 1,
    selected_courses = list(),
    user_logs = data.frame(timestamp = as.character(.POSIXct(Sys.time(), tz = "CET")), 
                           version = version, 
                           action = "session", 
                           value ="on")
  )
  
  ds = s3read_using(FUN = read.csv, object = "s3://bidm-bucket/data_courses_cleaned.csv") %>% select(-X)
  courses_by_categories <- list()
  for(cat in unique(ds$specialisation)){
    courses_by_categories[cat] = list(filter(ds, specialisation == cat)$title)
  }
  
  if (version == "test"){
    source('files/test_features.R', local = TRUE) 
  } else {
    source('files/control_features.R', local = TRUE) 
  }
  
  # 1st page
  observeEvent(input$start, {
    updateTabsetPanel(session, "exp", selected = "tab2")
    rv$user_logs = rbind(rv$user_logs, list(as.character(.POSIXct(Sys.time(), tz = "CET")), version, "start", 1))
    })
  
  # 2nd page
  
  log_awarness_set = observeEvent(input$courses, {
    rv$user_logs = rbind(rv$user_logs, list(as.character(.POSIXct(Sys.time(), tz = "CET")), version, "course_awareness", input$courses))
  })
  
      #
      # this block is different between version, check out files/ _features scripts.
      # 
  
  final_set_updater = observeEvent(input$final_set, {
    rv$selected_courses = input$final_set
    if (length(rv$selected_courses)>2 && length(rv$selected_courses)<6) {
      shinyjs::enable("final_confirm")}
    else {shinyjs::disable("final_confirm")}
  })
  
  observeEvent(input$final_confirm, {
    showNotification("Ваша заявка успешно сформирована, спасибо!
                     \nДля завершения эксперимента, пожалуйста, оцените ваш выбор.",
                     type = "message")
    hide(selector = ".evalpage")
    show("evaluation")
    updateTabsetPanel(session, "exp", selected = "tab3")
    rv$user_logs = rbind(rv$user_logs, list(as.character(.POSIXct(Sys.time(), tz = "CET")), version, "final_set", paste(input$final_set, collapse = '; ')))
  })
  
  # 3rd page
  
  selectionEval = observeEvent(input$subm, {
    
    # logs update + userId set
    rv$user_logs = rbind(rv$user_logs, list(as.character(.POSIXct(Sys.time(), tz = "CET")), version, "engagement", input$engagement))
    rv$user_logs = rbind(rv$user_logs, list(as.character(.POSIXct(Sys.time(), tz = "CET")), version, "transparency", input$engagement))
    rv$user_logs = rbind(rv$user_logs, list(as.character(.POSIXct(Sys.time(), tz = "CET")), version, "awareness", input$awareness))
    rv$user_logs = rbind(rv$user_logs, list(as.character(.POSIXct(Sys.time(), tz = "CET")), version, "caption", input$caption))
    logs = s3read_using(FUN = read.csv, object = "s3://bidm-bucket/logs.csv") %>% select(-X)
    user_code = max(logs$userId) + 1
    rv$user_logs = rv$user_logs %>% mutate(userId = user_code) %>% select(timestamp, userId, version, action, value)
    logs = rbind(logs, rv$user_logs)
    write.csv(logs, file.path(tempdir(), "logs.csv"))
    put_object(
      file = file.path(tempdir(), "logs.csv"),
      object = "logs.csv",
      bucket = s3BucketName)
    print("User logs are saved.")
    
    # reward_history update
    if(input$caption != "test" && difftime(as.POSIXct(filter(rv$user_logs, action == "transparency")$timestamp), as.POSIXct(filter(rv$user_logs, action == "start")$timestamp), units="secs") >= 120){
      reward_history = s3read_using(FUN = read.csv, object = "s3://bidm-bucket/reward_history.csv") %>% select(-X)
      current_arm_step = reward_history %>% 
        filter(version == version) %>%  
        select(step) %>% 
        max() + 1
      print(current_arm_step)
      reward_history = reward_history %>%
        rbind(list(version, current_arm_step, (input$engagement+input$transparency+input$awareness)/15, user_code))
      write.csv(reward_history, file.path(tempdir(), "reward_history.csv"))
      put_object(
        file = file.path(tempdir(), "reward_history.csv"),
        object = "reward_history.csv",
        bucket = s3BucketName)
      print("Reward history has been updated.")
      }
    
    # # popup
    popuptext = sprintf("Код подтверждения: %s. Спасибо за ваш вклад в развитие науки и образования; ваши ответы были записаны. Для получения награды, скопируйте код выше и вставьте его на сайте эксперимента на Толоке. Всего доброго!", user_code)
    sendSweetAlert(
      session = session,
      title = "Спасибо за участие!",
      text = popuptext,
      type = "success"
    )  
    print(rv$user_logs)
    })
  
  }

# Run the application 
shinyApp(ui = ui, server = server)
