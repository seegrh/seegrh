#!/bin/bash
SNAP_NAME='snaptmp'
SNAP_SIZE='2G'
LV_CURRENT=`df / | grep /$ | sed -e 's/ .*//g'`
VG_CURRENT=`lvs $LV_CURRENT -o vg_name --noheading | sed -e 's/.* //g'`


#a definir en temp qu alias de pacman
#[1] si l'option "u" existe alors on execute la suite sinon on passe a letape [3]
if [[ $1 =~ .*-.*u.* ]]; then
	#tester si on se trouve sur un snapshot
	if lvs $LV_CURRENT -o lv_attr --noheading | grep "^  s" 1>/dev/null ;then
		echo -e "Vous etes sur une snapshot etes vous sur de vouloir realiser une mise a jour ?(o/n)"
		#si oui demander confirmation avant de faire la mise a jour
		read snapshot
		case "$snapshot" in
				o|O)
		;;
				*) echo "Abandon..." 
				exit 1
		;;
		esac
	#si on est sur un snapshot on saute la partie suivante et on passe a letape [3]	
	else
		#recherche du snapshot precédent tmp
		if [ -L  /dev/$VG_CURRENT/$SNAP_NAME ];then
		#si il existe on le supprime et on affiche la date de création du snapshot suprimé
		echo -e "####SUPRESSION DU SNAPSHOT####\n"
				if echo "y" | lvremove /dev/$VG_CURRENT/$SNAP_NAME 2>/dev/null; then
				#suppression de l'entree grub
					echo -e "####SUPPRESSION ENTREE GRUB\n"
					sed -i '/'"$SNAP_NAME"'/,+10d' /etc/grub.d/40_custom
		#			grub-mkconfig -o /boot/grub/grub.cfg
					echo -e "\nSUCCESS\n"
				else
					echo "Command failed"
					exit 1
				fi
		fi
		#creation du snapshot
		echo -e "####CREATION DU SNAPSHOT####\n"
				if lvcreate --snapshot --name $SNAP_NAME --size $SNAP_SIZE $LV_CURRENT ; then
					echo -e "\nSNAPSHOT OK\n"
				else
					echo "Command failed"
					exit 1
				fi
				#creation de l'entree grub
				echo -e "####PREPARATION DE GRUB####"
				if ! grep -riq $SNAP_NAME /etc/grub.d/40_custom ; then
					echo -e "####CREATION D UNE ENTREE GRUB\n"
					echo -e "menuentry '$SNAP_NAME' --class arch --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-/dev/mapper/$VG_CURRENT-$SNAP_NAME' {
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
				echo -e "####MISE A JOUR DE GRUB####\n"
				grub-mkconfig -o /boot/grub/grub.cfg
		#verification que tout que le snapshot est bien cree
		#si il y a une erreur on de le notifie et demande confirmation pour continuer	
	fi
fi
#[3] execution du gestionaire de paquet
sudo -u ether yaourt $*
