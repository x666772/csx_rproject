library(httr)
library(RCurl)
library(XML)
library(dplyr)
library(readtext)
library(tm)
library(jiebaR)
library(jiebaRD)
library(tmcn)
library(tidytext)
library(ggplot2)

data <- list()

url  <- "https://mojim.com/twh107409.htm"
html <- htmlParse( GET(url) )
url.list <- xpathSApply( html, "//span[@class='hc3' or @class='hc4']/a[@href]", xmlAttrs )
for( i in 1:104) {
 data <- rbind( data, paste('https://mojim.com', url.list[[i]][1], sep='') )
}
data <- unlist(data)
data<-gsub("https://mojim.com_blank", "", data)
data<-gsub("https://mojim.com/twy107409x4x10.htm", "", data)
data<-gsub("https://mojim.com/twy107409x4x11.htm", "", data)
data<-gsub("https://mojim.com/twy107409x3x7.htm", "", data)

data<-data[data!=""]



getdoc <- function(url)
{
  html <- htmlParse( getURL(url) )
  doc  <- xpathSApply( html, "//*[(@id = 'fsZx3')]", xmlValue )
  song <- xpathSApply( html, "//div[@id='Tb3']/a[5]", xmlValue )
  name <- paste('C:/Users/USER/Documents/GitHub/csx_rproject/week_5/data/', song, ".txt")
  write(doc, name, append = TRUE)
}

sapply(data, getdoc)


page <- readtext("C:/Users/USER/Documents/GitHub/csx_rproject/week_5/data/*.txt", encoding = "big5")
corpus <- Corpus(VectorSource(page$text))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, removeNumbers)
corpus <- tm_map(corpus, stripWhitespace)
corpus <- tm_map(corpus, function(word) {
  gsub("[A-Za-z0-9]", "", word)
})
toSpace <- content_transformer(function(x, pattern) {
  return (gsub(pattern, " ", x))}
)
corpus <- tm_map(corpus, toSpace, "\\W")
myStopWords <- c("更多更詳盡歌詞","Mojim.com","魔鏡歌詞網", "作曲", "作詞", "編曲", "蛋", "堡", "杜", "振", "熙", "杜振熙純音樂")
corpus <- tm_map(corpus, toSpace, myStopWords)


mixseg = worker()
jieba_tokenizer = function(c)
{
  ( segment(c[[1]], mixseg) )
}
seg = lapply(corpus, jieba_tokenizer)

seg<-Filter(length, seg)

corpuss <- Corpus(VectorSource(seg))


tdm <- DocumentTermMatrix(corpuss)
inspect(tdm)
inspect(tdm[50:59, 500:505])

tidy<-tidy(tdm)
tidy<- tidy %>%
  filter(term != "蛋堡") %>%
  filter(term != "純音樂") %>%
  filter(term != "編曲")%>%
  filter(term != "杜振熙")%>%
  filter(term != "歌詞網")%>%
  filter(term != "感謝")

tidy <- tidy %>%
  bind_tf_idf(term, document, count)
tidy

tidyf<- as.data.frame(tidy)

tidyf$document<-as.numeric(tidyf$document) 

tidyf<-tidyf %>%
  mutate(word = factor(term, levels = rev(unique(term)))) %>%
  mutate(album = document %/% 10)

tidyf$document<-as.factor(tidyf$document) 
tidyf$album<-as.factor(tidyf$album) 

tidyf %>%
  group_by(album) %>% 
  top_n(20,tf_idf) %>% 
  arrange(desc(tf_idf)) %>%

  ggplot(aes(word, tf_idf, fill = album)) +
  geom_col(show.legend = FALSE) +
  labs(x = "album", y = "tf-idf") +
  facet_wrap(~album, ncol = 4, scales = "free_y") +
  coord_flip()



