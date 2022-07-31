
<!-- README.md is generated from README.Rmd. Please edit that file -->

# leninism

<!-- badges: start -->
<!-- badges: end -->

The goal of leninism is to provide the works of Lenin in the original
Russian in which they were written in an analysis-ready format.

If you would prefer to work with Lenin’s work in English, please see
[leninature](https://github.com/alicirce/leninature). These databases
are not fully comparable; some documents may be present in one and not
in the other.

# Getting started

## The Easy Way

If you would like to use the tidy data in the format provided, simply
install this package from github using devtools:

``` r
devtools::install_github("alicirce/leninism")
```

Then, simply load the package and play around with the available data
frame, `leninru`

``` r
library(leninism)
library(dplyr, warn.conflicts = FALSE)

leninru %>%
  head(10) %>%
  mutate(text = substring(text, 1, 30)) # for nicer README printing
## # A tibble: 10 × 5
##      vol doc_number section       year text                             
##    <dbl>      <int> <chr>        <dbl> <chr>                            
##  1     1          1 frontmatter   1893 ""                               
##  2     1          2 frontmatter   1893 "AnnotationВ первый том входят " 
##  3     1          3 frontmatter   1893 "Ленин \nПолное собрание сочинен"
##  4     1          4 frontmatter   1893 "Предисловие к полному собранию" 
##  5     1          5 frontmatter   1893 "Предисловие к первому тому В п" 
##  6     1          6 sectionstart  1893 "1893 г."                        
##  7     1          7 main          1893 "Новые хозяйственные движения в" 
##  8     1          8 main          1893 "По поводу так называемого вопр" 
##  9     1          9 sectionstart  1894 "1894 г."                        
## 10     1         10 main          1894 "Что такое «друзья народа» и ка"
```

## For Experts

If you would like to run the data compilation scripts yourself from
scratch, you will need to download calibre, an open source and freely
available epub editing tool.

The scripts in `data-raw` will download eBooks (FictionBook format) from
[leninism.su](leninism.su), convert them to epub, read them into R, and
tidy the data into a more usable data frame.

## I don’t want to use R

If you’d like the tidied data available in this package, but would
prefer to use another language to perform your analysis, assuming you
have R installed and you’ve downloaded this package from github using
the code above, you can run the following lines to export the data as a
CSV file:

``` r
library(leninism)
write.csv(leninru, "lenin_ru.csv", row.names = FALSE)
```
