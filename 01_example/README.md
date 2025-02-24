## Set the directory and pull the grass docker for a given operating system, create subbasins, elevation bands and zonal statistics of elevation bands or stat for elevation values

The docker image for grass can be found here. https://grass.osgeo.org/download/docker/

If needed load the necessary module for example `module reset; module purge; module load StdEnv/2020 gcc/9.3.0 apptainer` or install `apptainer`.

navigate to the given directory and pull and run the grass image using apptainer. 

```
cd ~/scratch # cd to home or the directory to build the sif file. 
export APPTAINER_CACHEDIR=$(pwd) # currecnt directory
rm -rf *.sif cache/
apptainer pull docker://osgeo/grass-gis:releasebranch_8_3-debian
apptainer run grass-gis_releasebranch_8_3-debian.sif
rm -rf GISDATA/ # remove possible GISDATA
grass -c EPSG:4326 GISDATA #create possible GISDATA and start a grass session
```

example inside the grass gis
```
# create the directories, input, output directories
base_directory="/home/shg096/GRASS_APPTAINER_TEST"
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
```

set the domain and read the file
```
# set global domain
g.region -d

# read the elevation file and set the region
r.in.gdal input="$input_directory"/n50w110_elv.tif output=elevation_map --o

#set the region or update
g.region raster=elevation_map -p #-o
```

fill, remove the depression and do the river network to non depression zones
```
# fill the DEM
r.fill.dir input=elevation_map format=grass output=filled direction=dir areas=depressions --o

# remove -1 to null in the depressions
r.null map=depressions setnull=-1
r.mapcalc "filled = if(isnull(depressions), filled, null())" --o

# execute the watershed
r.watershed elevation=filled threshold=1000 accumulation=acc drainage=ddir stream=stream basin=basins --o
```

used the filled dem and stream to estimate distance and hand
```
g.extension r.stream.distance # Ensure the module is available
r.stream.distance elevation=filled direction=ddir stream_rast=stream method=downstream distance=distance difference=HAND --o
r.out.gdal input=HAND output=HAND.tif format=GTiff type=Float64 --o
# save HAND lower than 1 meter
r.mapcalc "HAND_1m = if(HAND > 1, null(), HAND)"
r.out.gdal input=HAND_1m output=HAND_1m.tif format="GTiff" --o
```

save the outputs
```
# output streams
r.thin input=stream output=streamt --o
r.to.vect input=streamt output=streamv type=line -s --o
v.out.ogr input=streamv layer=1 type=line format=GPKG output="$output_directory"/stream_lines.gpkg output_layer=default -e -c --o

# output subbasins
r.to.vect input=basins output=basinsv type=area -s --o
v.out.ogr input=basinsv layer=1 type=area format=GPKG output="$output_directory"/subbasins.gpkg output_layer=default -e -c --o

# save the depression area as raster and shapefile
r.out.gdal input=depressions output=depressions.tif format=GTiff type=Float64 --o
r.to.vect input=depressions output=depressionsv type=area -s --o
v.out.ogr input=depressionsv layer=1 type=area format=GPKG output="$output_directory"/depressions.gpkg output_layer=default -e -c --o

# save on the filled DEM without depressions
r.out.gdal input=filled output="$output_directory"/filled.tif format=GTiff type=Float64 --o
```

zonal statistic for subbasins and elevation map
```
# Run v.rast.stats to calculate statistics
v.rast.stats map=basinsv raster=filled column_prefix=stats

# Export the attribute table of the vector layer to a CSV file
v.db.select map=basinsv separator=comma file="$output_directory"/ele_stat.csv -c --o
```

creation of elevation zones for each 100 meters, save as tif (and shapefile)
```
# Run mapcalc for zones of 100 meter (for positive) between -100 to 0 will be also zero
r.mapcalc "filled_zones = int(filled / 100) * 100" --o # maybe r.clump should be used, but it messed the result!
r.out.gdal input=filled_zones output="$output_directory"/filled_zones.tif format=GTiff type=Float64 --o

# save on the zoned filled DEM without depressions
r.to.vect input=filled_zones output=filled_zonesv type=area -s --o
v.out.ogr input=filled_zonesv layer=1 type=area format=GPKG output="$output_directory"/filled_zones.gpkg output_layer=default -e -c --o
```

zonal statistic for fraction of each elevation zone (discrete values like land cover)
```
g.extension r.zonal.classes # from grassaddons
v.to.rast input=basinsv output=basinsr use=cat --o # if needed bring back the vector to raster
r.zonal.classes raster=filled_zones zone_map=basinsr csvfile="$output_directory"/basin_elezone_frac.csv --o separator=comma # prefix=frac
```
