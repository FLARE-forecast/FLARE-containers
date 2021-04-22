#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("Container name is required as an argument.", call.=FALSE)
}

library(dplyr)

#source files and set paths on container
#these directories won't change on container
print(paste("Running NOAA scripts starting at:", as.character(Sys.time())))

#Read configuration file
config <- yaml::read_yaml(file.path("/root/flare/shared", args[1], "flare-config.yml"))
output_directory <- file.path(config$flare_shared_path, config$container$name)

#Read list of latitude and longitudes
site_list <- config$lake_name_code
lat_list <- config$lake_latitude
lon_list <- config$lake_longitude

noaaGEFSpoint::noaa_gefs_download_downscale(read_from_path = config$read_from_path,
                                            site_list,
                                            lat_list,
                                            lon_list,
                                            output_directory,
                                            forecast_time = config$forecast_time,
                                            forecast_date = config$forecast_date,
                                            downscale = config$downscale,
                                            run_parallel = config$run_parallel,
                                            num_cores = config$num_cores,
                                            method = "point",
                                            overwrite = config$overwrite)
