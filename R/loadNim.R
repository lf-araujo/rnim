# loadNim
#
# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'
#' Loads a Nim library file to R memory
#'
#' @param name Name of library file
#' @param path Local path to nim
loadNim <- function(name, path) {
  if (missing(path)) path <- "~/.nimble/bin/"
  Sys.setenv(PATH = paste0(path, Sys.getenv("PATH")))
  nim.installed <- invisible(system(paste0(path, "nim -v"))) == 0
  if (!nim.installed) {
    message("You havent installed Nim! Please follow installation instructions from https://nim-lang.org/")
    stop()
  }
  # rnim.installed <- invisible(system(paste0(path,"nimble list -i | grep 'rnim'")))==0
  # if (!rnim.installed){
  #   message("You don't have rnim installed, please run nimble install rnim")
  #   stop()
  # }
  if (Sys.getenv("R_HOME")=="") Sys.setenv(R_HOME = file.path(R.home("bin"), "R"))
  if (Sys.getenv("LD_LIBRARY_PATH")=="") Sys.setenv(LD_LIBRARY_PATH = file.path(R.home()))
  system(paste0(path, "nim c --app:lib ", name))
  dyn.load(paste0("lib", name, ".so"))
  source(paste0(name,'.R'))
}
