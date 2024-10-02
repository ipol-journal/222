#!/bin/bash

if [ "$#" -lt "13" ]; then
  echo "usage:\n\t$0 nscales zoom eps transform robust lambda dbp edgepadding color gradient first_scale std eq"
  exit 1
fi

nscales=$1
zoom=$2
eps=$3
transform=$4
robust=$5
lambda=$6
dbp=$7
edgepadding=$8
color=$9
gradient=${10}
first_scale=${11}
std=${12}
eq=${13}

if [ "$color" = "True" ]; then
  GRAYMETHOD=1
else
  GRAYMETHOD=0
fi

if [ "$dbp" = "True" ]; then
  NANIFOUTSIDE=1
else
  NANIFOUTSIDE=0
  edgepadding=0
fi

ref=input_0.png
ref_noisy=input_noisy_0.png
warped=input_1.png
warped_noisy=input_noisy_1.png
file=transformation.txt
filewithout=transformation_without.txt
if [ -f input_2.txt ]; then
    file2=input_2.txt
else
    file2=""
fi

w=`identify -format "%w" $ref`
h=`identify -format "%h" $ref`
w2=`identify -format "%w" $warped`
h2=`identify -format "%h" $warped`
minsize=32
testw=`echo "$w - $minsize" | bc`
testh=`echo "$h - $minsize" | bc`

if [ "$testw" -le "0" -o "$testh" -le "0" ]; then
  echo "The input image is too small" > demo_failure.txt
  echo "The current input image is of size $w x $h" >> demo_failure.txt
  echo "The minimal input image size is of $minsize pixels" >> demo_failure.txt
  cp demo_failure.txt stdout.txt
elif [ "$w" -ne "$w2" -o "$h" -ne "$h2" ]; then
  echo "Input images must have the same size" > demo_failure.txt
  echo "The first input image is of size $w x $h" >> demo_failure.txt
  echo "The second input image is of size $w2 x $h2" >> demo_failure.txt
  cp demo_failure.txt stdout.txt
else
  if [ "$eq" = "none" ]; then
      cp $warped $warped_noisy
  else
      echo "Contrasts of the images are equalized"
      equalization $ref $warped $warped_noisy $eq
  fi

  echo "Standard deviation of the noise added: $std"
  add_noise $ref $ref_noisy $std
  add_noise $warped_noisy $warped_noisy $std

  echo ""
  inverse_compositional_algorithm $ref_noisy $warped_noisy -f $filewithout -z $zoom -n $nscales -r $robust -e $eps -t $transform -s 0 -c 0 -d 0 -p 0 -g 0 > /dev/null
  inverse_compositional_algorithm $ref_noisy $warped_noisy -f $file -z $zoom -n $nscales -r $robust -e $eps -t $transform -s $first_scale -c $GRAYMETHOD -d $edgepadding -p $NANIFOUTSIDE -g $gradient -v

  echo ""
  echo "Without modification:"
  generate_output $ref_noisy $warped_noisy $filewithout $file2
  mv output_estimated.png output_estimated2.png
  if [ -f epe.png ]; then
      mv epe.png epe2.png
      echo "vis=1" > algo_info.txt
  fi
  mv diff_image.png diff_image2.png

  echo ""
  echo "With modifications:"
  generate_output $ref_noisy $warped_noisy $file $file2
fi
