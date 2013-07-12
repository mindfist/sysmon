#!/bin/sh

export GDFONTPATH=/usr/share/fonts/liberation
export GNUPLOT_DEFAULT_GDFONT=LiberationSans-Regular

REPORT_CPU=/tmp/gnuplot.cpu
REPORT_MEM=/tmp/gnuplot.mem
REPORT_NET=/tmp/gnuplot.net
REPORT_LOAD=/tmp/gnuplot.load
REPORT_IO=/tmp/gnuplot.io

MAX_X_AXIS=348
MAX_Y_AXIS=100

echo enter file name:
read fname
   
cpu_stat(){
awk '
 BEGIN{}
   {
    if (NR == 1) {
      old_user = $2;
      old_nice = $3;
      old_sys = $4;
      old_idle = $5;
    } else {
      if ( old_user > $2 ){
        user = 0;
        nice = 0;
        sys = 0;
        idle = 0;
        reboot = 100;
      } else {
        user = $2 - old_user;
        nice = $3 - old_nice;
        sys = $4 - old_sys;
        idle = $5 - old_idle;
        reboot = -1;
      }
      total = user + nice + sys + idle ;
      if ( user == 0 ) { puser = 0; } else {
     puser= (user / total) * 100;}
      if ( sys  == 0 ) { psys  = 0; } else {
     psys = (sys  / total) * 100;}
      if ( nice == 0 ) { pnice = 0; } else {
     pnice= (nice / total) * 100;}
      if ( idle == 0 ) { pidle = 0; } else {
     pidle= (idle / total) * 100;}
     
     con = $1
      printf("%7.2f %7.2f %7.2f %7.2f %d\n", pidle+puser+psys+pnice, puser+psys+pnice, psys+pnice, pnice,con) >"/tmp/gnuplot.cpu";
      old_user = $2;
      old_nice = $3;
      old_sys = $4;
      old_idle = $5;
    }
   }
   END{}' ${fname}
}

mem_stat(){
awk '
 BEGIN{ MEMUSED=0; MEMTOTAL=0; MEMFREE=0; MemTotal=0; }
     {
       MemTotal=$6;
       MemFree=$7;
       Buffers=$8;
       Cached=$9;

       MEMUSED=(( ( ( ( MemTotal - MemFree ) - Cached ) - Buffers ) / 1024 ));
       MEMTOTAL=(( MemTotal / 1024));
       MEMFREE=(( MEMTOTAL - MEMUSED ));
       con=$1

       printf("%d %d %d %d\n", MEMUSED, MEMTOTAL, MEMFREE, con) >"/tmp/gnuplot.mem";

     }
   END{}' ${fname}
}

net_stat(){
awk '
 BEGIN{}
   {
    if (NR == 1) {
      old_in = $11;
      old_out = $12;
    } else {
      if ( old_in > $11 ) {
        net_in = 0;
        net_out = 0;
      } else {
        net_in = $11 - old_in;
        net_out = $12 - old_out;
      }
      if ( net_in == 0 ) { pin = 0; } else {
     pin= (net_in / 1024) / 1024;}
      if ( net_out  == 0 ) { pout = 0; } else {
     pout = (net_out / 1024) / 1024;}
    
      con = $1
      printf("-%d %d %d\n", pin, pout, con) >"/tmp/gnuplot.net";
      old_user = $11;
      old_nice = $12;
    }
   }
   END{}' ${fname}
}

loadavg_stat(){
awk '
  BEGIN{}
    {
      loadavg = $13;
      con = $1;
   
      printf("%d %2.2f\n", con, loadavg) > "/tmp/gnuplot.load";
    }
  END{}' ${fname}
}

IOstat(){
awk '
  BEGIN{}
    {
    if (NR == 1) {
      old_read = $14;
      old_write = $15;
    } else {
      if ( old_in > $14 ) {
        io_read = 0;
        io_write = 0;
      } else {
        io_read = $14 - old_read;
        io_write = $15 - old_write;
      }
      if ( io_read == 0 ) { pread = 0; } else {
     pread = io_read;}
      if ( io_write  == 0 ) { pwrite = 0; } else {
     pwrite = io_write;}
    
      con = $1
      printf("-%d %d %d\n", pread, pwrite, con) >"/tmp/gnuplot.io";
      old_user = $14;
      old_nice = $15;
    }
   }
   END{}' ${fname}
}


IOBlk(){
awk '
  BEGIN{}
    {
      bk_read = $16;
      bk_write = $17;
      con = $1;
   
      printf("%d %9.2f %9.2f\n", con, bk_read, bk_write) > "/tmp/gnuplot.iobk";
    }
  END{}' ${fname}
}

#parse CPU stats /proc/stats
cpu_stat

# parse Mem stats /proc/meminfo
mem_stat

# parse net stats /proc/net/dev
net_stat

# parse loadavg stats
loadavg_stat

# parse IOstat 
IOstat

# parse IOstat block_per_sec
IOBlk

cat > stat_cpu.gnu << EOF
set term png size 550,450 font "LiberationSans-Regular,10" 
set output "cpu.png"

set title "CPU v/s Concurrency"
set style data line
set style fill transparent solid 0.3
set format y "%3.2f"
set xrange [*:*]
set yrange [*:*]
set xlabel "Concurrency level"
set ylabel " CPU (%)"
set key left invert font "LiberationSans-Regular,8" 

set grid
#set key left
plot '$REPORT_CPU' using 5:1 title 'Total CPU' with filledcurves y1=0.0 lt rgb "dark-green" lw 1,\
    '$REPORT_CPU' using 5:2 title 'User CPU' with filledcurves y1=0.0 lt rgb "#dd0000" lw 1,\
    '$REPORT_CPU' using 5:3 title 'System CPU' with filledcurves y1=0.0 lt rgb "#dddd00" lw 1,\
    '$REPORT_CPU' using 5:4 title 'Nice CPU' with filledcurves y1=0.0 lt rgb "#0000dd" lw 1
    
set terminal png
replot

EOF

cat > stat_mem.gnu << EOF
set term png size 550,450 font "LiberationSans-Regular,10"
set output "mem.png"

set title "Mem v/s Concurrency"
set style data line
set style fill transparent solid 0.3
set xrange [*:*]
set yrange [*:*]
set xlabel "Concurrency level"
set ylabel " Mem (MB)"
set key horiz
set key left invert font "LiberationSans-Regular,8" 

set grid
#set key left
plot '$REPORT_MEM' using 4:2 title 'Total Mem' with filledcurves y1=0.0 lt rgb "dark-green" lw 1,\
    '$REPORT_MEM' using 4:3 title 'Mem Free' with filledcurves y1=0.0 lt rgb "dark-yellow" lw 1,\
    '$REPORT_MEM' using 4:1 title 'Mem Used' with filledcurves y1=0.0 lt rgb "#dd0000" lw 1
    
set terminal png
replot

EOF

cat > stat_net.gnu << EOF
set term png size 550,450 font "LiberationSans-Regular,10"
set output "net.png"

set style data line
set style fill transparent solid 0.3
set style function filledcurves y1=0
set grid

set xrange [*:*]
set yrange [*:*]
set title "Net Traffic v/s Concurrency"
set xlabel "Concurrency"
set ylabel "Mbytes"
set key left invert font "LiberationSans-Regular,8"

plot '$REPORT_NET' using 3:1 title 'In' with filledcurves y1=0 lt rgb 'dark-blue' lw 1,\
     '$REPORT_NET' using 3:2 title 'Out' with filledcurves y1=0 lt rgb 'dark-green' lw 1

EOF

cat > stat_loadavg.gnu << EOF
set term png size 550,450 font "LiberationSans-Regular,10"
set output "loadavg.png"

set style data lines
set style fill transparent solid 0.3
set style function filledcurves y1=0
set format y "%3.2f"
set grid

set xrange [*:*]
set yrange [*:*]
set title "load avg v/s Concurrency"
set xlabel "Concurrency"
set ylabel "Load"
set key left invert font "LiberationSans-Regular,8"

plot '$REPORT_LOAD' using 1:2 title 'Load' with filledcurves y1=0 lt rgb 'dark-blue' lw 1

EOF

cat > stat_io.gnu << EOF
set term png size 550,450 font "LiberationSans-Regular,10"
set output "io.png"

set style data line
set style fill transparent solid 0.3
set style function filledcurves y1=0
set grid

set xrange [*:*]
set yrange [*:*]
set title "IO Stat v/s Concurrency"
set xlabel "Concurrency"
set ylabel "Blocks"
set key left invert font "LiberationSans-Regular,8"

plot '$REPORT_IO' using 3:1 title 'block read' with filledcurves y1=0 lt rgb 'dark-blue' lw 1,\
     '$REPORT_IO' using 3:2 title 'block write' with filledcurves y1=0 lt rgb 'dark-green' lw 1

EOF

gnuplot stat_cpu.gnu
gnuplot stat_mem.gnu
gnuplot stat_net.gnu
gnuplot stat_loadavg.gnu
gnuplot stat_io.gnu
