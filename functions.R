stitch <- function(x, video_dir, fr, temp_dir) {

  message(x$cat[1], " - ", x$batch[1], ": ")

  message("  - Omitting corrupted files")
  imgs <- x %>%
    mutate(imgs = map(pics, ~try(image_read(.), silent = TRUE)),
           img_valid = map_lgl(imgs, ~!any(class(.) %in% "try-error"))) %>%
    filter(img_valid)

  message("  - Converting to PNG to save end-corrupted files")
  imgs <- imgs %>%
    mutate(imgs = map(imgs, ~image_write(., path = NULL, format = "png") %>% image_read()))

  message("  - Annotating")
  imgs <- mutate(imgs,
                 #imgs = map(pics, image_read),
                 imgs = pmap(list(imgs, start, dur, gps, gps_error),
                             ~image_annotate(
                               ..1,
                               paste0(as.character(..2), " UTC (", round(..3, 1), "s)\n",
                                      "(", ..4, ") ± ", ..5, "m"),
                               size = 15, color = "white",
                               boxcolor = "black",
                               gravity = "southwest")))


  message("  - Joining images and rendering video")
  video_dir <- file.path(video_dir, imgs$cat[1])
  if(!dir.exists(video_dir)) dir.create(video_dir)
  image_join(imgs$imgs) %>%
    image_write_video(file.path(video_dir, imgs$video_name[1]),
                      framerate = fr)
  invisible()
}
