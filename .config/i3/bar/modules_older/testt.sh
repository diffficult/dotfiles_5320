#!/bin/bash
mx=$(($(tput cols)/2));my=$(($(tput lines)-1));s=${1:-1000};cx=${2:--500};cy=${3:-0};
i=${4:-20};co=${5:-8};__="echo -ne ";___="return";:(){ [ $1 -lt $i ] || {
$__ "\x1b[m "; $___;};[ $((($4*$4)+($5*$5))) -gt 4000000000 ] && { :p $(($1-3));$___;};
: $(($1+1)) $2 $3 $((((($4*$4)-($5*$5))/10000)+$2)) $(((2*$4*$5)/10000+$3));};
:p(){ c=$1; [ $1 -lt 0 ] && c=0; [ $1 -gt $co ] && c=$(($1%$co+1)); $__ "\x1b[3$(($c))m$c";};
:_(){ [ $1 -lt $my ] || $___;:__ $1 -$mx;:_ $(($1+2));};:__(){ [ $2 -lt $mx ] || {
echo;$___;};: 0 $(($cx+$2*$s)) $(($cy+$1*$s)) 0 0;:__ $1 $(($2+1));};:_ -$my;
n="\x1b[m";r="\x1b[31m";g="\x1b[33m";echo -ne "${n}usage: mb step shiftx${r}[${g}-2500${r}:${g}1600${r}]$n ";
echo -e "shifty${r}[${g}-1500${r}:${g}1500${r}]$n iterations colors${r}[${g}1${r}:${g}8${r}]$n";exit 0