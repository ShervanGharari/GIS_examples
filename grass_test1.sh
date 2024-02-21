# test 1
cd
module reset
module purge
module load StdEnv/2020  gcc/9.3.0 grass/8.2.1

rm -rf ~/GISDATA/

grass -c EPSG:4326 ~/GISDATA

# read the elevation file and set the region
#r.in.gdal input=n55w095_elv.tif output=elevation_map --o
r.in.gdal input=n50w110_elv.tif output=elevation_map --o
g.region raster=elevation_map

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
