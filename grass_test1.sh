# test 1

rm -rf ~/GISDATA/

grass -c EPSG:4326 ~/GISDATA

#g.region n=54.999583333333334 s=49.999583333333334 e=-105.00041666666667 w=-110.00041666666667 res=0.0008333333333333334

# read the elevation file and set the region
r.in.gdal input=n50w110_elv.tif output=elevation_map  --o
g.region raster=elevation_map

# fill the DEM
r.fill.dir input=elevation_map format=grass output=filled direction=dir --o

# execute the watershed
r.watershed elevation=filled threshold=1000 accumulation=acc drainage=ddir stream=stream basin=basins --o

# output streams
r.thin input=stream output=streamt type=line --o
r.to.vect input=streamt output=streamv type=line -s --o
v.out.ogr input=streamv layer=1 type=line format=GPKG output=~/stream_lines.gpkg output_layer=default -e -c --o

# output subbasins
r.to.vect input=basins output=basinsv type=area -s --o
v.out.ogr input=basinsv layer=1 type=area format=GPKG output=~/subbasins.gpkg output_layer=default -e -c --o
