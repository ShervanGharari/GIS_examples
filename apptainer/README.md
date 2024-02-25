## step one: set the directory and pull the grass docker for a given operating system

The docker image for grass can be found here. https://grass.osgeo.org/download/docker/

navigate to the given directory and pull and run the grass image using apptainer

```
cd ~/scratch
export APPTAINER_CACHEDIR=/home/shg096/scratch/
apptainer pull docker://osgeo/grass-gis:releasebranch_8_3-debian
apptainer run grass-gis_releasebranch_8_3-debian.sif
rm -rf GISDATA/ # remove possible GISDATA
grass -c EPSG:4326 GISDATA #create possible GISDATA and grass session
```

example inside the grass gis

```
# create the directories, input, output directories
base_directory="/home/shg096/GRASS_APPTAINER_TEST/grass"
input_directory="${base_directory}"/input
output_directory="${base_directory}"/output
# Check if the output directory exists
if [ ! -d "$output_directory" ]; then
    # If the directory doesn't exist, create it
    mkdir -p "$output_directory"
    echo "Output directory '$output_directory' created."
else
    echo "Output directory '$output_directory' already exists."
fi

# set global domain
g.region -d

# read the elevation file and set the region
r.in.gdal input="$output_directory"/n50w110_elv.tif output=elevation_map --o

#set the region or update
g.region raster=elevation_map -p #-o

# fill the DEM
r.fill.dir input=elevation_map format=grass output=filled direction=dir areas=depressions --o

# remove -1 to null in the depressions
r.null map=depressions setnull=-1
r.mapcalc "filled = if(isnull(depressions), filled, null())" --o

# execute the watershed
r.watershed elevation=filled threshold=1000 accumulation=acc drainage=ddir stream=stream basin=basins --o

# output streams
r.thin input=stream output=streamt --o
r.to.vect input=streamt output=streamv type=line -s --o
v.out.ogr input=streamv layer=1 type=line format=GPKG output=~/stream_lines.gpkg output_layer=default -e -c --o

# output subbasins
r.to.vect input=basins output=basinsv type=area -s --o
v.out.ogr input=basinsv layer=1 type=area format=GPKG output=~/subbasins.gpkg output_layer=default -e -c --o

# save the depression area as raster and shapefile
r.out.gdal input=depressions output=depressions.tif format=GTiff type=Float64 --o
r.to.vect input=depressions output=depressionsv type=area -s --o
v.out.ogr input=depressionsv layer=1 type=area format=GPKG output=~/depressions.gpkg output_layer=default -e -c --o

# save on the filled DEM without depressions
r.out.gdal input=filled output=filled.tif format=GTiff type=Float64 --o
```
