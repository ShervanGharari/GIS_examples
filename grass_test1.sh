# test 1
cd
module reset
module purge
module load StdEnv/2020 gcc/9.3.0 grass/8.2.1

rm -rf ~/GISDATA/

grass -c EPSG:4326 ~/GISDATA

# set global domain
g.region -d

# read the elevation file and set the region
r.in.gdal input=n50w110_elv.tif output=elevation_map --o

# THE MERGE PART DOES NOT WORK
# # or batch read and merge
# # Get a list of files matching the pattern dem*.tif
# dem_files=(n*w*_elv.tif)
# # Import each DEM raster into the GRASS GIS location
# for ((i=0; i<${#dem_files[@]}; i++)); do
#     r.in.gdal input="${dem_files[$i]}" output=dem$i
# done
# # Create a comma-separated list of DEMs for r.patch
# dem_list=$(echo $(for ((i=0; i<${#dem_files[@]}; i++)); do echo -n "dem$i,"; done) | sed 's/,$//')
# # Merge the DEMs into a single raster using r.patch
# r.patch input=$dem_list output=elevation_map #--o

#set the region or update
g.region raster=elevation_map -p #-o

# get the raster info
r.info input=elevation_map

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

