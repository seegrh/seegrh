#!/bin/bash
SNAP_NAME='snaptmp'
SNAP_GRUBMENU_NAME='Last update snapshot'
SNAP_SIZE='2G'
LV_CURRENT=`df / | grep /$ | sed -e 's/ .*//g'`
VG_CURRENT=`lvs $LV_CURRENT -o vg_name --noheading | sed -e 's/.* //g'`


#a definir en temp qu alias de pacman
#[1] si l'option "u" existe alors on execute la suite sinon on passe a letape [3]
if [[ $1 =~ .*-.*u.* ]]; then
	#tester si on se trouve sur un snapshot
	if lvs $LV_CURRENT -o lv_attr --noheading | grep "^  s" 1>/dev/null ;then
		echo -e "Vous etes sur un snapshot etes vous sur de vouloir realiser une mise a jour ?(o/n)"
		#si oui demander confirmation avant de faire la mise a jour
		read snapshot
		case "$snapshot" in
				o|O)
				sudo -u ether yaourt $*
				exit 0
		;;
				*) echo "Abandon..." 
				exit 1
		;;
		esac
	#si on est sur un snapshot on saute la partie suivante et on passe a letape [3]	
	else
		#recherche du snapshot precédent tmp
		if [ -L  /dev/$VG_CURRENT/$SNAP_NAME ];then
			echo -e "\n################ DERNIER SNAPSHOT ################"
			#si il existe on affiche son nom sa date de creation et sont utilisation
			lvs /dev/$VG_CURRENT/$SNAP_NAME -o lv_name,lv_time,snap_percent
			echo -e "##################################################\n"
			echo -e "Voulez vous supprimer le dernier snapshot ?(o/n)"
					read delsnapshot
		case "$delsnapshot" in
				o|O)
				#si oui on le supprime 
				echo -e "############ SUPPRESSION DU SNAPSHOT ############"
				if echo "y" | lvremove /dev/$VG_CURRENT/$SNAP_NAME 2>/dev/null; then
				#suppression de l'entree grub
					echo -e "############## MISE A JOUR DE GRUB ##############"
					echo "Suppression de l entree Grub"
					sed -i '/'"$SNAP_GRUBMENU_NAME"'/,+10d' /etc/grub.d/40_custom
				else
					echo "Erreur"
					exit 1
				fi
				#creation du snapshot
		echo -e "############## CREATION DU SNAPSHOT ##############"
				if lvcreate --snapshot --name $SNAP_NAME --size $SNAP_SIZE $LV_CURRENT ; then
					echo "done"
				else
					echo "Erreur"
					exit 1
				fi
				#creation de l'entree grub
				echo -e "############## PREPARATION DE GRUB ##############"
				if ! grep -riq '$SNAP_GRUBMENU_NAME' /etc/grub.d/40_custom ; then
					echo -e "Creation de l entree Grub"
					echo -e "menuentry '$SNAP_GRUBMENU_NAME' --class arch --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-/dev/mapper/$VG_CURRENT-$SNAP_NAME' {
		load_video
		set gfxpayload=keep
		insmod gzio
		insmod part_msdos
		insmod lvm
		insmod ext2
		set root='lvmid/a2ZUlA-iTgQ-hF0x-cVdO-eU0M-RvKL-rVWXDB/3GMS3F-BZCj-mL8j-NVBc-adhT-7sAP-xWpu9B'
		linux   /vmlinuz-linux root=/dev/mapper/$VG_CURRENT-$SNAP_NAME rw dolvm quiet
		initrd   /initramfs-linux.img
}" >>/etc/grub.d/40_custom
				fi
				#update de grub
				echo -e "############## MISE A JOUR DE GRUB ##############"
				grub-mkconfig -o /boot/grub/grub.cfg
		#verification que tout que le snapshot est bien cree
		#si il y a une erreur on de le notifie et demande confirmation pour continuer
		echo -e "##################################################\n"	
		;;
				*) echo "########### MISE A JOUR SANS SNAPSHOT ############" 
		;;
		esac
		else
			echo -e "Voulez vous creer un snapshot ?(o/n)"
			read createsnapshot
			case "$createsnapshot" in
				o|O)
				#si oui on le cree
				#creation du snapshot
				echo -e "############## CREATION DU SNAPSHOT ##############"
				if lvcreate --snapshot --name $SNAP_NAME --size $SNAP_SIZE $LV_CURRENT ; then
					echo "done"
				else
					echo "Erreur"
					exit 1
				fi
				#creation de l'entree grub
				echo -e "############## PREPARATION DE GRUB ##############"
				if ! grep -riq '$SNAP_GRUBMENU_NAME' /etc/grub.d/40_custom ; then
					echo -e "Creation de l entree Grub"
					echo -e "menuentry '$SNAP_GRUBMENU_NAME' --class arch --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-/dev/mapper/$VG_CURRENT-$SNAP_NAME' {
		load_video
		set gfxpayload=keep
		insmod gzio
		insmod part_msdos
		insmod lvm
		insmod ext2
		set root='lvmid/a2ZUlA-iTgQ-hF0x-cVdO-eU0M-RvKL-rVWXDB/3GMS3F-BZCj-mL8j-NVBc-adhT-7sAP-xWpu9B'
		linux   /vmlinuz-linux root=/dev/mapper/$VG_CURRENT-$SNAP_NAME rw dolvm quiet
		initrd   /initramfs-linux.img
}" >>/etc/grub.d/40_custom
				fi
				#update de grub
				echo -e "############## MISE A JOUR DE GRUB ##############"
				grub-mkconfig -o /boot/grub/grub.cfg
				#verification que tout que le snapshot est bien cree
				#si il y a une erreur on de le notifie et demande confirmation pour continuer
				echo -e "##################################################\n"
			;;
				*)
			;;
			esac
		fi
	fi
fi
#[3] execution du gestionaire de paquet
sudo -u ether yaourt $*
exit 0
