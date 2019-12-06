

pacman -Rsn discover modemmanager-qt plasma-nm

# Suppression des jeux (paquet fltk indispensable à tigervnc qui est nécessaire à xrdp)
# et raccourcis FLUID
rm -f /usr/share/icons/hicolor/128x128/apps/blocks.png
rm -f /usr/share/icons/hicolor/128x128/apps/checkers.png
rm -f /usr/share/icons/hicolor/128x128/apps/sudoku.png
rm -f /usr/share/applications/blocks.desktop
rm -f /usr/share/applications/checkers.desktop
rm -f /usr/share/applications/fluid.desktop
rm -f /usr/share/applications/sudoku.desktop
rm -f /usr/bin/blocks
rm -f /usr/bin/checkers
rm -f /usr/bin/sudoku
rm -f /usr/share/man/man6/blocks.6.gz
rm -f /usr/share/man/man6/checkers.6.gz
rm -f /usr/share/man/man6/sudoku.6.gz

pacman -Rsn networkmanager wpa_supplicant networkmanager-qt plasma-vault powerdevil
