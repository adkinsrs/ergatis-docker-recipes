# Ergatis Code Differences

This is a collection of differences between component code used in the internal IGS version of the LGTSeek pipeline in Ergatis, and the Docker version.

* blast2lca
  * Removed config file references to taxanomy dump files
  * Changed MongoDB connection address in config file
* sam2lca
  * Removed config file references to taxanomy dump files
  * Changed MongoDB connection address in config file
* blast\_lgt\_finder
  * Removed config file references to taxanomy dump files
  * Changed MongoDB connection address in config file
* split\_multifasta
  * Changed the number of sequences per output file to 500 (was 100 internally)
