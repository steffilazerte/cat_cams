# Resources
# - https://cran.r-project.org/web/packages/magick/vignettes/intro.html
# - https://ryanpeek.github.io/2016-10-19-animated-gif_maps_in_R/

library(magick)
library(tidyverse)
library(lubridate)
#install.packages("av") # Required by magick to create the mp4 videos

# Get the functions for reading dates from the DATE.TXT file and for creating the videos
source("functions.R")

# SETUP
out_dir <- file.path("Videos") # Location for output
in_dir <- file.path("Catcam footage") # Location of input files
resume <- TRUE # Whether to overwrite existing files or resume from last file
               # (unique to the file type)


# RUN

# Create output dir
if(!dir.exists(video_dir)) dir.create(video_dir)

# Get files
f <- list.files(in_dir, full.names = TRUE, recursive = TRUE)

videos <- read_csv("Catcams/deployment.csv") %>%
  mutate(time = ymd_hm(time),
         date = as_date(time),
         files = map(.data$cat, ~str_subset(f, .)),
         video = map(.data$files, ~na.omit(unique(str_extract(., "\\bCAP[0-9]{1,3}\\b"))))) %>%
  unnest(video) %>%
  mutate(pics = pmap(list(files, video, date),
                     ~str_subset(..1, file.path(..2, ..3))),
         video_time = map_chr(pics, ~read_date(str_subset(., "DATE.TXT"))),
         pics = map(pics, ~.[!str_detect(., "DATE.TXT")]),
         real_time = time + hms(video_time)) %>%
  select(-files) %>%
  unnest(pics) %>%
  # Sort frames correctly
  mutate(pic_n = str_extract(pics, "[0-9]{1,4}.JPG"),
         pic_n = as.numeric(str_remove(pic_n, ".JPG"))) %>%
  arrange(cat, video, pic_n) %>%
  # Set video names and see if any have already been created
  mutate(video_name = paste0(cat, "_", real_time, "_", video, ".mp4"),
         created = file.exists(file.path(video_dir, cat, video_name)))

# Videos with no frams
no_frames <- videos %>%
  filter(is.na(pic_n))

# Read pics, rotate and annotate
pics <- videos %>%
  filter(!is.na(pic_n))

# If you want to resume (i.e. not redo files already finished)
if(resume) pics <- filter(pics, !created)

pics %>%
  select(-pic_n) %>%
  mutate(cat1 = cat) %>%
  nest(data = c(cat, video, real_time, pics, video_name)) %>%
  mutate(data = map(data, ~stitch(., video_dir, fr)))
