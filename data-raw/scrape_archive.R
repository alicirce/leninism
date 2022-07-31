# This script downloads FictionBook (fb2) files from leninism.su, which include
# all of Lenin's works, in the original Russian they were written in. This
# script uses calibre, a free and open source tool for working with epub files.

# update this file path to be where you would like to save the fb2 files:
save_to <- "../leninism_archive/"

# set up environment
library(rvest)
library(dplyr)
library(epubr)
library(tidyr)
url <- "https://leninism.su/works.html"



# get fb2 links
main_page <- read_html(url)
main_page_links <- main_page %>%
  html_elements(".categories-list") %>%
  html_elements("a") %>%
  html_attr("href") %>%
  as.character()
fb2_links <- main_page_links[grepl("FB2", main_page_links)]
tom_page_links <- main_page_links[grepl("html$", main_page_links)]

for (fb2 in fb2_links) {
  destfile <- paste0(save_to, gsub(".*/(.*.zip)$", "\\1", fb2))
  filesource <- paste0("https://leninism.su", fb2)
  download.file(filesource, destfile, mode = "wb")
  Sys.sleep(60)
}

# unzip and convert format to epub using calibre
setwd(save_to)
system("unzip -o \\*.zip")
fb2_files <- list.files(pattern = "fb2$")
stopifnot(length(fb2_files) == length(fb2_links))
fb2_files <- setdiff( # remove one file that is metadata only
  fb2_files,
  "Ленин Владимир. ПСС. Содержание и Алфавитный указатель - royallib.com.fb2"
)
for (fb2 in fb2_files) {
  system(paste("ebook-convert", fb2, gsub("fb2", "epub", fb2)))
}

epub_files <- list.files(pattern = "epub$")
stopifnot(length(epub_files) == length(fb2_files))
vol <- epub(epub_files[1])

# Store as data.frame
# meta datafields to keep: description? title
# check number of dataframes is 1? or bind_rows?
body <- bind_rows(vol$data)

# first rows are title page, TOC (starts with "Annotation"?), then a dedication
# Пролетарии всех стран, соединяйтесь Издание пятое Печатается по постановлению
# Центрального Комитета Коммунистической Партии Советского Союза

# Then theres a foreward which is a few pages long, ends with
#"Institute of Marxism-Leninism under the Central Committee of the CPSU"
#"Институт марксизма-ленинизма при ЦК КПСС"
# starts with Предисловие

all_vols <- data.frame(
  title = character(0),
  description = character(0),
  section = character(0),
  text = character(0)
)

for (fn in epub_files) {
  vol <- epub(fn)
  body <- vol$data[[1]] %>%
    select(section, text) %>%
    mutate(
      title = vol$title,
      description = vol$description
    )
  all_vols <- bind_rows(all_vols, body)
}

leninru <- all_vols %>%
  mutate(
    vol = as.numeric(
      gsub(".*том ([0-9]+).*", "\\1", title, ignore.case = TRUE)
    )
  ) %>%
  group_by(vol) %>%
  mutate(doc_number = row_number()) %>%
  ungroup()
attr(leninru$text, "names") <- NULL

# label footnotes: for vol 1-42 (excepting 28, 29, 33), these start with a
# section titled `Комментарии`
footnote_starts <- leninru %>%
  slice(
    which(grepl("Комментарии", text, ignore.case = T) & nchar(text) < 20)
  ) %>%
  select(vol, footnote_start = doc_number)

leninru <- leninru %>%
  left_join(footnote_starts, by = "vol") %>%
  mutate(
    section = ifelse(
      !is.na(footnote_start) & doc_number >= footnote_start,
      "footnotes",
      section
    )
  ) %>%
  select(-footnote_start)

# Volumes without footnotes have end notes, starting with `СОДЕРЖАНИЕ` (content)
# or `УКАЗАТЕЛЬ ИМЕН` (name index). Some mid-volume texts also have these
# strings, so this logic checks that this label is only applied to texts at the
# end of a volume.
leninru <- leninru %>%
  group_by(vol) %>%
  mutate(
    ndocs = max(doc_number),
    likely_end = grepl('СОДЕРЖАНИЕ|УКАЗАТЕЛЬ ИМЕН', text),
    section = case_when(
      likely_end & doc_number == ndocs ~ "endnote",
      likely_end & lead(likely_end)    ~ "endnote",
      TRUE                             ~  section
    )
  ) %>%
  select(-ndocs, -likely_end)

# Extract year; many volumes start with a section consisting entirely of the
# year. The first of this is the first non-frontmatter section, so use this
# to identify frontmatter.
leninru <- leninru %>%
  mutate(
    section = ifelse(
      nchar(text) < 20 & grepl("[0-9]{4}", text),
      "sectionstart",
      section
    ),
    year = ifelse(
      nchar(text) < 20 & grepl("[0-9]{4}", text),
      suppressMessages(as.numeric(gsub(".*([0-9]{4}).*", "\\1", text))),
      NA_integer_
    )
  ) %>%
  group_by(vol) %>%
  fill(year, .direction = "down") %>%
  mutate(section = ifelse(
    !all(is.na(year)) & is.na(year),
    "frontmatter",
    section
  )) %>%
  fill(year, .direction = "up") %>%
  ungroup()

# Documents without year sections still have Forewards (ПРЕДИСЛОВИЕ), but
# they are always index 1 or 2 for a volume. Label these as frontmatter too.
leninru <- leninru %>%
  mutate(section = ifelse(
    grepl("ПРЕДИСЛОВИЕ", text) & doc_number < 3,
    "frontmatter",
    section
  ))

# all other sections, label as "main" for now
leninru <- leninru %>%
  mutate(section = ifelse(grepl("^id", section), "main", section))

# some volumes are still missing year and slipped through the other logic.
# handle manually for now, at least.

# Volume 3 is one book, written 1896-1899, published 1899. There's also a
# response to criticisms of this book, which was published in 1900
vol3 <- leninru %>%
  filter(vol == 3)
end_front_matter_at <- which(
  grepl("Настоящий том содержит произведение", vol3$text, ignore.case = T)
)
vol3$section[1:end_front_matter_at] <- "frontmatter"
vol3$year <- 1899
uncritical <- which(grepl("Некритическая критика", vol3$text))
uncritical <- uncritical[uncritical > 5][1:2]
vol3$year[uncritical[1]:uncritical[2]] <- 1900
endmatter <- which(grepl("^Даты работы", vol3$text)) # info on when Lenin wrote
footnotes <- which(vol3$text == "Примечания") # comments/footnotes
vol3$section[endmatter:footnotes] <- "endnote"
vol3$section[footnotes:nrow(vol3)] <- "footnotes"

leninru <- leninru %>%
  filter(vol != 3) %>%
  bind_rows(vol3)

# The others without years just had different arrangements. handle annoyingly:
leninru <- leninru %>%
  mutate(
    year = case_when(
      year == 1986 ~ 1896,            # typo
      vol == 28    ~ 1916,
      vol == 29    ~ NA_real_,        # notes compiled over many periods
      vol == 33    ~ 1918,            # state & revolution
      vol == 43    ~ 1921,
      vol == 44    ~ 1921,            # some also in 1922
      vol == 45    ~ 1922,            # some also in 1923
      vol == 46    ~ NA_real_,        # letters from many periods
      vol == 47    ~ NA_real_,        # 1905-1910
      vol == 48    ~ NA_real_,        # 1910-1914
      vol == 49    ~ NA_real_,        # 1914-1917
      vol == 50    ~ NA_real_,        # 1917-1919
      vol == 51    ~ NA_real_,        # 1919-1920
      vol == 52    ~ NA_real_,        # 1920-1921
      vol == 53    ~ 1921,
      vol == 54    ~ NA_real_,        # 1921-1923
      vol == 55    ~ NA_real_,        # 1893-1922
      TRUE         ~ year
  ))

# final tidy up and save
leninru_volumes <- leninru %>%
  select(vol, title, description) %>%
  arrange(vol) %>%
  unique()
leninru <- leninru %>%
  select(vol, doc_number, section, year, text) %>%
  arrange(vol, doc_number)

usethis::use_data(leninru, overwrite = TRUE)
usethis::use_data(leninru_volumes, overwrite = TRUE)
