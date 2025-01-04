filename mf lrecl=a0 blocksize=8000 recfm=fb;

proc cport library= file=;
run;

filename mf lrecl=a0 blocksize=8000 recfm=fb;

proc cimport library= infile=;
run;
