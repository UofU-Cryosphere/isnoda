docker run --rm  -v /Volumes/EastRiverSubset/topo/basin_setup:/data/topo \
                 -v /Volumes/DataDiskG/hrrr:/data/input   \
                 -v /Volumes/DataDiskG/ERW_subset/devel/wy2018/initial_run/data:/data/output  \
                 --user 530:20 usdaarsnwrc/katana:0.3.1 \
                 --start_date 20171001-00-00 --end_date 20171004-00-00 \
                 --input_directory /data/input --output_directory /data/output \
                 --wn_cfg /data/output/windninjarun.cfg \
                 --topo /data/topo/topo.nc \
                 --zn_number 13 \
                 --zn_letter N \
                 --buff 6000 \
                 --nthreads 3 \
                 --nthreads_w 1 \
                 --dxy 200 \
                 --loglevel info \
                 --logfile /data/output/log_katana_20171001-00-00.txt

