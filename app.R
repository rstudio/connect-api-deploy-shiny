# Text of the books downloaded from:
# A Mid Summer Night's Dream:
#  http://www.gutenberg.org/cache/epub/2242/pg2242.txt
# The Merchant of Venice:
#  http://www.gutenberg.org/cache/epub/2243/pg2243.txt
# Romeo and Juliet:
#  http://www.gutenberg.org/cache/epub/1112/pg1112.txt

library(shiny)
library(tm)
library(wordcloud)
library(memoise)

# The list of books and the root of the associated file name.
books <- list("A Mid Summer Night's Dream" = "summer",
              "The Merchant of Venice" = "merchant",
              "Romeo and Juliet" = "romeo")

# Using "memoise" to automatically cache the results
getTermMatrix <- memoise(function(book) {
  # Careful not to let just any name slip in here; a
  # malicious user could manipulate this value.
  if (!(book %in% books))
    stop("Unknown book")

  text <- readLines(sprintf("./data/%s.txt.gz", book),
    encoding = "UTF-8")

  myCorpus = Corpus(VectorSource(text))
  myCorpus = tm_map(myCorpus, content_transformer(tolower))
  myCorpus = tm_map(myCorpus, removePunctuation)
  myCorpus = tm_map(myCorpus, removeNumbers)
  myCorpus = tm_map(myCorpus, removeWords,
         c(stopwords("SMART"), "thy", "thou", "thee", "the", "and", "but"))

  myDTM = TermDocumentMatrix(myCorpus,
              control = list(minWordLength = 1))
  
  m = as.matrix(myDTM)
  
  sort(rowSums(m), decreasing = TRUE)
})

ui <- fluidPage(
  # Application title
  titlePanel("Word Cloud"),

  sidebarLayout(
    # Sidebar with a slider and selection inputs
    sidebarPanel(
      selectInput("selection", "Choose a book:",
                  choices = books),
      actionButton("update", "Change"),
      hr(),
      sliderInput("freq",
                  "Minimum Frequency:",
                  min = 1,  max = 50, value = 15),
      sliderInput("max",
                  "Maximum Number of Words:",
                  min = 1,  max = 300,  value = 100)
    ),

    # Show Word Cloud
    mainPanel(
      plotOutput("plot")
    )
  )
)

server <- function(input, output, session) {
  # Define a reactive expression for the document term matrix
  terms <- reactive({
    # Change when the "update" button is pressed...
    input$update
    # ...but not for anything else
    isolate({
      withProgress({
        setProgress(message = "Processing corpus...")
        getTermMatrix(input$selection)
      })
    })
  })

  # Make the wordcloud drawing predictable during a session
  wordcloud_rep <- repeatable(wordcloud::wordcloud)

  output$plot <- renderPlot({
    v <- terms()
    wordcloud_rep(names(v), v, scale = c(4,0.5),
                  min.freq = input$freq, max.words = input$max,
                  colors = RColorBrewer::brewer.pal(8, "Dark2"))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
