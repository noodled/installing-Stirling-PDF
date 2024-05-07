
echo Installing Stirling-PDF on a Debian or Ubuntu machine
echo All files and PDFs exist either exclusively on the client side, 
echo reside in server memory only during task execution, 
echo or temporarily reside in a file solely for the execution of the task. 
echo Any file downloaded by the user will have been deleted from the server by that point.
# 2024 April 30
sudo apt-get update -y
sudo apt-get install -y git automake autoconf libtool libleptonica-dev pkg-config \
     zlib1g-dev make g++ openjdk-17-jdk python3 python3-pip
mkdir -p /download && pushd /download
mkdir ~/.git
cd ~/.git &&\
git clone https://github.com/agl/jbig2enc.git &&\
cd jbig2enc &&\
./autogen.sh &&\
./configure &&\
make &&\
sudo make install
sudo apt-get install -y libreoffice-writer libreoffice-calc libreoffice-impress \
    unpaper ocrmypdf
python3 -m pip install uno opencv-python-headless unoconv pngquant WeasyPrint
# no ! --break-system-packages
# ubuntu 20.04 based mint 20.3 has problem
# ERROR: weasyprint 61.2 has requirement Pillow>=9.1.0, but you'll have pillow 7.0.0 which is incompatible.
pushd /download
wget https://files.pythonhosted.org/packages/4b/83/090146d7871d90a2643d469c319c1d014e41b315ab5cf0f8b4b6a764ef31/Pillow-9.1.0.tar.gz
tar xvf Pillow-9.1.0.tar.gz
pushd Pillow-9.1.0
sudo apt-get install -y python3-dev python3-setuptools
#pre req ubuntu 20.04 and 22.04
sudo apt-get install -y libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev \
    libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk \
    libharfbuzz-dev libfribidi-dev libxcb1-dev
#installing latest 10.3
python3 -m pip install --upgrade Pillow --no-binary :all:
#important note Found existing installation: Pillow 7.0.0 - Can't uninstall 'Pillow'. No files were found to uninstall 
python3 -m pip install WeasyPrint
popd -2
cd ~/.git &&\
git clone https://github.com/Stirling-Tools/Stirling-PDF.git &&\
cd Stirling-PDF &&\
chmod +x ./gradlew &&\
./gradlew build
sudo mkdir /opt/Stirling-PDF &&\
sudo mv ./build/libs/Stirling-PDF-*.jar /opt/Stirling-PDF/ &&\
sudo mv scripts /opt/Stirling-PDF/ &&\
echo "Scripts installed."
echo installing english dutch french german spanish and italian ocr files
sudo apt-get install -y tesseract-ocr-eng tesseract-ocr-nld tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-spa tesseract-ocr-ita
echo creating desktop icon
location=$(pwd)/gradlew
image=$(pwd)/docs/stirling-transparent.svg

cat <<EOF | sudo tee ~/.local/share/applications/Stirling-PDF.desktop
[Desktop Entry]
Name=Stirling PDF;
GenericName=Launch StirlingPDF and open its WebGUI;
Category=Office;
Exec=xdg-open http://localhost:8080 && nohup $location bootRun &;
Icon=$image;
Keywords=pdf;
Type=Application;
NoDisplay=false;
Terminal=true;
EOF

echo running as a service
sudo touch /opt/Stirling-PDF/.env

cat <<EOF | sudo tee /etc/systemd/system/stirlingpdf.service
[Unit]
Description=Stirling-PDF service
After=syslog.target network.target

[Service]
SuccessExitStatus=143

User=root
Group=root

Type=simple

EnvironmentFile=/opt/Stirling-PDF/.env
WorkingDirectory=/opt/Stirling-PDF
#ExecStart=/usr/bin/java -jar Stirling-PDF-0.23.1.jar
ExecStart=/usr/bin/java -jar echo $(ls /opt/Stirling-PDF/Stirling-PDF-*.jar | tail -1)
ExecStop=/bin/kill -15 $MAINPID

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl status stirlingpdf.service
sudo systemctl start stirlingpdf.service
sudo systemctl stop stirlingpdf.service
sudo systemctl restart stirlingpdf.service
sudo systemctl status stirlingpdf.service | grep -e'Running' && sudo systemctl enable stirlingpdf.service

echo checking what PID used port 8080
echo fuser -n tcp 8080
## to run manually ./gradlew bootRun
##  or
## java -jar /opt/Stirling-PDF/Stirling-PDF-*.jar

# https://github.com/Stirling-Tools/Stirling-PDF/blob/main/LocalRunGuide.md
# info about authentication : https://github.com/Stirling-Tools/Stirling-PDF/tree/main#login-authentication
# folderscanning :) https://github.com/Stirling-Tools/Stirling-PDF/blob/main/FolderScanning.md
# info about OCR https://github.com/Stirling-Tools/Stirling-PDF/blob/main/HowToUseOCR.md#ocr-language-packs-and-setup
# info if some local languages are desired https://github.com/Stirling-Tools/Stirling-PDF/blob/main/HowToAddNewLanguage.md


