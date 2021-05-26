library(magick)
library(tidyverse)
library(lubridate)

# SETUP
in_dir <- file.path("Catcam footage") # Location of input files
resume <- FALSE # Whether to overwrite existing files or resume from last file
                # (unique to the file type)

# Get the functions for reading dates from the DATE.TXT file and for creating the videos
source("functions.R")

# RUN
# Create folders
out_dir <- file.path("Videos") # Location for output
if(!dir.exists(out_dir)) dir.create(out_dir)

# Get batches
f <- list.files(in_dir, pattern = "cap", full.names = TRUE, recursive = TRUE, include.dirs = TRUE)

videos <- tibble(f = f) %>%
  mutate(cat = str_extract(f, "[A-Z]{3}[0-9]{2}"),
         batch = str_extract(f, "cap[0-9]+"),
         meta = map(f, ~read_lines(file.path(., "data.txt"))),
         date = map(meta, ~ymd(str_extract(.[1], "[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}"))),
         end_time = map(meta, ~str_extract(.[2], "[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}")),
         dur = map(meta, ~str_extract(.[3], "[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}")),
         gps = map(meta, ~str_extract(.[4], "[0-9.\\-,]+$")),
         gps_error = map(meta, ~str_extract(.[5], "[0-9]+"))) %>%
  unnest(cols = c(date, end_time, dur, gps, gps_error)) %>%
  mutate(gps_error = as.numeric(gps_error) / 1000,
         gps = map(gps, ~as.numeric(str_split(., ",", simplify = TRUE)) / 10000000),
         gps = map_chr(gps, paste0, collapse = ", "),
         dur = as.numeric(hms(dur)),
         end = ymd_hms(paste(date, end_time)),
         start = end - dur,
         pics = map(f, ~list.files(., pattern = "jpg", full.names = TRUE, recursive = TRUE))) %>%
  unnest(pics) %>%
  # Sort frames correctly
  mutate(pic_n = str_extract(pics, "[0-9]{1,4}.jpg"),
         pic_n = as.numeric(str_remove(pic_n, ".jpg"))) %>%
  group_by(cat, batch) %>%
  mutate(frame_rate = (n() - 1) / dur) %>%
  ungroup() %>%
  arrange(cat, batch, pic_n) %>%
  # Set video names and see if any have already been created
  mutate(video_name = paste0(cat, "_", start, "_", batch, ".mp4"),
         created = file.exists(file.path(out_dir, cat, video_name))) %>%
  select(cat, batch, frame_rate, date, start, dur, gps, gps_error,
         pics, pic_n, video_name, created)

# Videos with no frames
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
  nest(data = c(cat, batch, start, dur, pics, gps, gps_error, video_name)) %>%
  mutate(data = map2(data, frame_rate, ~stitch(.x, out_dir, fr = .y, temp_dir)))
