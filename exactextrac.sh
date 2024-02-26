```
cd ~/ # cd to home or the directory to build the sif file. 
export APPTAINER_CACHEDIR=$(pwd) # currecnt directory
rm -rf *.sif cache/
apptainer pull docker://isciences/exactextract
apptainer run exactextract_latest.sif -r "/home/shg096/GRASS_APPTAINER_TEST/output/filled_zones.tif" -p /home/shg096/GRASS_APPTAINER_TEST/output/subbasins.gpkg.shp -s "frac" -o ~/output.csv
```

cd ~/ # cd to home or the directory to build the sif file. 
export APPTAINER_CACHEDIR=$(pwd) # currecnt directory
rm -rf *.sif cache/
apptainer pull docker://isciences/exactextract-build-env
apptainer run exactextract-build-env_latest.sif
