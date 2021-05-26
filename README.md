# Cat Cams

These scripts are for 'stitching' together pictures from cat collar cameras into 
videos.

- `stitch.R` is the main script
- `functions.R`

## 1. Install packages
To get started, first install the following packages:

```
install.packages(c("magick", "tidyverse", "lubridate", "av"))
```

## 2. Increase memory allocated to Image Magick

- https://bigbinary.com/blog/configuring-memory-allocation-in-imagemagick

In R, type the following
```
system("identify -list policy")
```

It should tell you where your "policy.xml" file is, as well as your allocated memory

```
Path: /etc/ImageMagick-6/policy.xml
  Policy: Resource
    name: disk
    value: 5GiB
  Policy: Resource
    name: map
    value: 512MiB
  Policy: Resource
    name: memory
    value: 10GiB
...
```

Change the policy.xml file at this point:

`<policy domain="resource" name="memory" value="256MiB"/>`

to

`<policy domain="resource" name="memory" value="1GiB"/>`

(or what every memory value you can spare, you can see that I used 10GiB)

Then run `system("identify -list policy")` again to check that it has been updated


## 3. Change the folder locations
In `stitch.R`, adjust the locations of `in_dir` to match the place where your photos are stored

For example:

```
> Catcam footage
  > BUN12          <- These folder names DO matter (and should be format of AAA00)
    > 4May2021     <- These folder names DO NOT matter
      > cap46      <- These folder names DO matter
        - data.txt
        > 1
          - 1.jpg
          - 2.jpg 
          - ...
      > cap48 
        - data.txt
        > 1
          - ...
  > JOR11
    > 4May2021
      ...
    > 5May2011
           ...
```

## 4. Change resume

If you want to resume a run, use `resume = TRUE`

## 5. Run the entire `stitch.R` script

## 6. Look in `Videos/IDNAME/` for the compiled video.


# Resources

- https://cran.r-project.org/web/packages/magick/vignettes/intro.html
- https://ryanpeek.github.io/2016-10-19-animated-gif_maps_in_R/
