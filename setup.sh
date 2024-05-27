#!/bin/sh

LOG_FILE="/usr/local/captive-portal/error.txt"
: > $LOG_FILE  # Clear the log file

log_error() {
    echo "$1" >> $LOG_FILE
}

check_status() {
    if [ $? -eq 0 ]; then
        echo "$1: OK"
    else
        echo "$1: FAIL"
        log_error "$1: FAIL"
    fi
}

echo "FreeBSD güncelleniyor ve gerekli paketler kuruluyor..."
pkg update && pkg upgrade -y
check_status "FreeBSD güncelleme ve paket kurulumu"

echo "Gerekli paketler kuruluyor..."
pkg install -y python3 py39-virtualenv py39-sqlite3 py39-openssl nginx bash curl wget tar gcc gmake tk86 tcl86 xorg-minimal
check_status "Gerekli paketlerin kurulumu"

echo "Rust derleyicisi kuruluyor..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
check_status "Rust kurulumu"
source $HOME/.cargo/env

echo "Python sanal ortamı oluşturuluyor..."
python3.9 -m venv /usr/local/captive-portal/venv
check_status "Python sanal ortamı oluşturma"
. /usr/local/captive-portal/venv/bin/activate

echo "Pip güncelleniyor ve bağımlılıklar kuruluyor..."
pip install --upgrade pip
check_status "Pip güncellemesi"
pip install flask requests pyOpenSSL zeep cryptography sqlalchemy flask-login pyyaml flask_sqlalchemy lxml
check_status "Python bağımlılıklarının kurulumu"

echo "Uygulama dosyaları indiriliyor..."
mkdir -p /usr/local/captive-portal
cd /usr/local/captive-portal
if [ -f "main.zip" ]; then rm main.zip; fi
wget https://github.com/yourusername/your-repo-name/archive/main.zip
check_status "Uygulama dosyalarının indirilmesi"
unzip main.zip
check_status "Uygulama dosyalarının açılması"
mv your-repo-name-main/* .
check_status "Uygulama dosyalarının taşınması"
rm -rf your-repo-name-main main.zip

echo "Config dosyası düzenleniyor..."
cat <<EOF > /usr/local/captive-portal/config.yaml
admin:
  username: "cpadmin"
  password: "123456"
database:
  uri: "sqlite:////usr/local/captive-portal/database.db"
captive_portal:
  ip: "192.168.1.2"
  port: 5000
nginx:
  listen_port: 80
  server_name: "192.168.1.2"
EOF
check_status "Config dosyasının düzenlenmesi"

echo "NGINX yapılandırması yapılıyor..."
cat <<EOF > /usr/local/etc/nginx/nginx.conf
server {
    listen 80;
    server_name 192.168.1.2;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
check_status "NGINX yapılandırması"
service nginx restart
check_status "NGINX yeniden başlatılması"

echo "Sistem yönlendirmesi etkinleştiriliyor..."
echo "net.inet.ip.forwarding=1" >> /etc/sysctl.conf
sysctl net.inet.ip.forwarding=1
check_status "Sistem yönlendirmesi etkinleştirilmesi"

echo "PF konfigürasyonu yapılıyor..."
cat <<EOF > /etc/pf.conf
ext_if="em0"
captive_portal_ip="192.168.1.2"

scrub in all
nat on \$ext_if from any to any -> (\$ext_if)

rdr pass on \$ext_if proto tcp from any to any port 80 -> \$captive_portal_ip port 80
rdr pass on \$ext_if proto tcp from any to any port 443 -> \$captive_portal_ip port 80
rdr pass on \$ext_if proto udp from any to any port 53 -> \$captive_portal_ip port 53

block in all
pass in proto tcp from any to \$captive_portal_ip port 80
pass in proto tcp from any to \$captive_portal_ip port 443
pass in proto udp from any to \$captive_portal_ip port 53
EOF
check_status "PF konfigürasyonu"
pfctl -f /etc/pf.conf
check_status "PF kurallarının yüklenmesi"
pfctl -e
check_status "PF etkinleştirilmesi"

echo "Flask uygulaması başlatılıyor..."
cat <<EOF > /etc/rc.local
#!/bin/sh
. /usr/local/captive-portal/venv/bin/activate
python /usr/local/captive-portal/app.py &
EOF
check_status "Flask uygulaması başlatma dosyasının oluşturulması"
chmod +x /etc/rc.local
/etc/rc.local
check_status "Flask uygulaması başlatılması"

echo "Kurulum tamamlandı!"
