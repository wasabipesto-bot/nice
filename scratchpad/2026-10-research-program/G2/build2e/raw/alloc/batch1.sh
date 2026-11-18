bash arun.sh e1_init64 q64a.json 1 before 150 0
bash arun.sh e2_mid64 q64a.json 1 before 2000 0
bash arun.sh e3_late64 q64a.json 1 before 6000 0
bash arun.sh e4_end64 q64a.json 1 before 7800 0
bash arun.sh e5_after64 q64ab.json 2 after 0 5
bash arun.sh base62 q62.json 1 none 0 0
bash arun.sh e6_mid62 q62.json 1 before 3000 0
bash arun.sh base64s q64small.json 1 none 0 0
bash arun.sh e7_init64s q64small.json 1 before 150 0
echo BATCH-DONE
