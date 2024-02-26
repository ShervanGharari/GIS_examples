```
cd ~/ # cd to home or the directory to build the sif file. 
rm -rf *.sif cache/
apptainer pull docker://isciences/exactextract
apptainer run exactextract_latest.sif \
  -r "DEM:/home/shg096/GRASS_APPTAINER_TEST/output/filled.tif" \
  -p /home/shg096/GRASS_APPTAINER_TEST/output/subbasins.gpkg \
  -f cat \
  -s "mean(DEM)" \
  -o ~/output.csv
```

compilation
```
cd
module purge
module reset
module load StdEnv/2020 gcc/9.3.0 geos gdal cmake

cd
rm -rf exactextract
git clone https://github.com/isciences/exactextract.git --branch v0.1.0
cd exactextract/
mkdir cmake-build-release
cd cmake-build-release
cmake -DCMAKE_BUILD_TYPE=Release ..
make
```
