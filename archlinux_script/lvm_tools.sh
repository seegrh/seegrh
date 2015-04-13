#!/bin/bash
lvm_group='lvm_group'
lv_system='lv_system0'
lv_system_size=''
lv_target=''
lv_current=''
lv_clone=''
workspace=''
snapsize='1G'
snaptmp='snaptmp'
snapprefix='snap'

#num=`ls -1rv /dev/lvm_group/ -I ws_*| grep lv_system | head -1 | sed -e 's/lv_system//g'`
#numws=0
#numws=`ls -1rv /dev/lvm_group/ | grep ws_lv_system | head -1 | sed -e 's/ws_lv_system._//g'`

#increment du dernier volume systeme exitant
#num=$(($num + 1))
#numws=$(($numws + 1))
 
#lv_clone="lv_system$num"
#lv_current=`df . | grep lv_system | sed -e 's/ .*//g'`

#nom complet du volume ou se trouve la racine
#chemin lv system current : 
#df . | grep /$ | sed -e 's/ .*//g'

#nom du volume systeme actuel
#lvs `df . | grep /$ | sed -e 's/ .*//g'` -o lv_name --noheading | sed -e 's/.* //g'

#vg system current
#MOCHE
#lvdisplay `df . | grep /$ | sed -e 's/ .*//g'` | grep "VG Name" | sed 's/ *.*. //g'
#BEAU
#lvs `df . | grep /$ | sed -e 's/ .*//g'` -o vg_name --noheading | sed -e 's/.* //g'

echo -e "####LVM_TOOLS####"

#Toute les operation doivent se faire sur le systel de fstab
#if  ! echo $lv_current | grep -q $lv_system ;then
# #$lv_current !=$lv_system ; then
# echo -e "Veuillez redémrrer sur $lv_system"
# exit 1
#fi

echo -e "\nChoisir l'action a realiser\n"
echo -e "[1] Creation d un snapshot\n[2] Fusioner un snapshot\n[3] Suppression d un snapshot"
read cmenu

case "$cmenu" in
1)  echo -e "####Creation d un snapshot####"


 echo -e "####LISTE DES VOLUMES####\n"

index=1
#afficher les volumes logiques qui ne sont pas des snapshots
        for i in `lvs -o lv_attr,lv_name --noheading | grep -v "^  s" | sed 's/  .......... //'`; do
                lvtab["$index"]=$i
                echo "[$index] $i"
                let "index=$index+1"
        done

 echo -e "\nChoisir le volume logique a utiliser pour effectuer le snapshot :"
 read lvselect
 lvselect=$lvselect
 if [[ "$(echo $lvselect | grep "^[ [:digit:] ]*$")" && $lvselect -lt $index ]]
 then
  echo -e "Etes vous sur de vouloir faire un snapshot du volume ${lvtab[$lvselect]} (o/n) ?"
 else
  echo "Ereur"
  exit 1
 fi

 read rep1

 case "$rep1" in
  o|O)
  snapnumber=`ls -1rv /dev/$lvm_group/ | grep snap_${lvtab[$lvselect]} | head -1 | sed -e 's/snap_'"${lvtab[$lvselect]}"'_//g'`
  if [ "$snapnumber" = "" ] ; then 
   snapnumber=0
  fi
  snapnumber=$(($snapnumber + 1))
  snapname='snap_'"${lvtab[$lvselect]}"'_'"$snapnumber"
  echo -e "####CREATION DU SNAPSHOT####\n"
  if lvcreate --snapshot --name $snapname --size $snapsize /dev/$lvm_group/${lvtab[$lvselect]} ; then
   echo -e "\nSNAPSHOT OK\n"
  else
   echo "Command failed"
   exit 1
  fi

  echo -e "####PREPARATION DE GRUB####\n"

  if ! grep -riq $snapname/etc/grub.d/40_custom ; then
   echo -e "####CREATION D UNE ENTREE GRUB\n"
   echo -e "menuentry '$snapname' --class arch --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-/dev/mapper/$lvm_group-$snapname' {
        load_video
        set gfxpayload=keep
        insmod gzio
        insmod part_msdos
        insmod ext2
        set root='hd0,msdos1'
        linux   /vmlinuz-linux root=/dev/mapper/$lvm_group-$snapname rw dolvm quiet
        initrd   /initramfs-linux.img
}" >>/etc/grub.d/40_custom
  fi
  echo -e "####MISE A JOUR DE GRUB####\n"
  grub-mkconfig -o /boot/grub/grub.cfg
#  echo -e "Souhaitez vous saisir une description (o/n)\n"
#  read repdesc
#  case "$repdesc" in
#  o|O)
#  descverif=0
#  while [ "$descverif" = 0 ]
#   do
#   echo -e "Saisir la description :\n"
#   read snapdesc
#   echo -e "la description "$snapdesc" est correcte (o/n)\n"
#   read repverif
#   case "$repverif" in
#   o|O)
#   #verifier que le fichier est creer
#   if [ grep -riq "$snapname" ]
#   #verifier que l'entrée existe sinon remplacer la ligne
#   then
#    echo -n "$snapname;$snapdesc\n">>aff
#   fi
#   descverif=1
#   ;;
#   *)
#   echo -e "saisie incorrecte"
#   ;;
#   esac
#  done
#  ;;
#  esac
  echo -e "###VOLUMES CREEES###\n"
  lvs /dev/$lvm_group/$snapname
  #choisir description sed -n 's/<snapname>;//p' aff (aff fichier <snapname>;<snapdescr>
 ;;
  n|N) echo "Abandon..." 
 exit 1
 ;;

 *) echo "Aucun choix" 
 exit 1
 ;;
 esac


exit 1
;;
2) echo -e "####Fusionner un snapshot####"

 echo -e "####LISTE DES SYSTEMES####\n"

 index=1
 for i in `lvs -o lv_attr,lv_name --noheading | grep "^  s" | sed 's/  .......... //'`; do
  snaptab["$index"]=$i
  echo "[$index] $i"
  let "index=$index+1"
 done
 if [ "${snaptab[*]}" = "" ] ; then
  echo -e "aucun snapshot disponible"
  exit 0
 fi
 echo -e "\nChoisir le snapshot a fusionner :"
 read snapselect
 snapselect=$snapselect
 if [[ "$(echo $snapselect | grep "^[ [:digit:] ]*$")" && $snapselect -lt $index ]]
 then
  echo -e "Etes vous sur de vouloir fusionner ${snaptab[$snapselect]} (o/n) ?"
 else
  echo "Ereur"
  exit 1
 fi

 read rep1

 case "$rep1" in
  o|O)
  echo -e "####FUSION DU SNAPSHOT####\n"
  if echo "y" | lvconvert --merge /dev/$lvm_group/${snaptab[$snapselect]} 2>/dev/null; then
   echo -e "####SUPPRESSION ENTREE GRUB\n"
   sed -i '/'"${snaptab[$snapselect]}"'/,+10d' /etc/grub.d/40_custom
   grub-mkconfig -o /boot/grub/grub.cfg
   echo -e "\nSUCCESS\n"
   echo "Veuillez redemarrer pour finir l'operation"
  else
   echo "Erreur"
   exit 1
  fi
  ;;

  n|N) echo "Abandon..." 
 exit 1
 ;;

 *) echo "Aucun choix" 
 exit 1
 ;;
 esac

exit 1
;;

3) echo -e "####Supression d un snapshot####"

 echo -e "####LISTE DES SYSTEMES####\n"

 index=1
 for i in `lvs -o lv_attr,lv_name --noheading | grep "^  s" | sed 's/  .......... //'`; do
  snaptab["$index"]=$i
  echo "[$index] $i"
  let "index=$index+1"
 done
 if [ "${snaptab[*]}" = "" ] ; then
  echo -e "aucun snapshot disponible"
  exit 0
 fi
 echo -e "\nChoisir le snapshot a supprimer :"
 read snapselect
 snapselect=$snapselect
 if [[ "$(echo $snapselect | grep "^[ [:digit:] ]*$")" && $snapselect -lt $index ]]
 then
  echo -e "Etes vous sur de vouloir supprimer ${snaptab[$snapselect]} (o/n) ?"
 else
  echo "Ereur"
  exit 1
 fi

 read rep1

 case "$rep1" in
  o|O)
  echo -e "####SUPRESSION DU SNAPSHOT####\n"
  if echo "y" | lvremove /dev/$lvm_group/${snaptab[$snapselect]} 2>/dev/null; then
   echo -e "####SUPPRESSION ENTREE GRUB\n"
   sed -i '/'"${snaptab[$snapselect]}"'/,+10d' /etc/grub.d/40_custom
   grub-mkconfig -o /boot/grub/grub.cfg
   echo -e "\nSUCCESS\n"
  else
   echo "Command failed"
   exit 1
  fi
  ;;

  n|N) echo "Abandon..." 
 exit 1
 ;;

 *) echo "Aucun choix" 
 exit 1
 ;;
 esac

exit 1
;;

*) echo "Aucun choix" 
exit 1
;;
esac

#A faire:
#verifier que l on se trouve vien sur system0 pour faire l update de grub
#checker l existance de snaptmp
#supprimer snaptmp en cas d'erreur
#Ajouter les prerequis
#lister les systeme
#SUPPRESSION DE LA CONFIG DANS GRUB
#
#
#
#
