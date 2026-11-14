for i in 1 2 3 4 5; do
./t.sh newS_$i FXS - --ignored --exact cubecl_backend::tests::cubecl_queues_check_every_survivor_on_partly_filled_planes --nocapture
./t.sh newW_$i FXW - --ignored --exact cubecl_backend::tests::cubecl_queues_check_every_survivor_on_partly_filled_planes --nocapture
done
