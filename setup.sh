#!/bin/sh

# FreeBSD Güncelleme ve Paket Kurulumu
echo "FreeBSD güncelleniyor ve gerekli paketler kuruluyor..."
pkg update
pkg upgrade -y
pkg install -y python3 py37-pip py37-virtualenv py37-sqlite3 py37-openssl nginx

# Python Sanal Ortamının Kurulumu
echo "Python sanal ortamı oluşturuluyor..."
python3 -m venv /usr/local/captive-portal/venv
source /usr/local/captive-portal/venv/bin/activate
pip install flask requests pyOpenSSL zeep cryptography sqlalchemy flask-login pyyaml

# Uygulama Dosyalarının İndirilmesi
echo "Uygulama dosyaları indiriliyor..."
mkdir -p /usr/local/captive-portal
cd /usr/local/captive-portal
fetch https://github.com/yourusername/your-repo-name/archive/main.zip
unzip main.zip
mv your-repo-name-main/* .
rm -rf your-repo-name-main main.zip

# Config dosyasını düzenleyin
echo "Config dosyası düzenleniyor..."
cat <<EOF > /usr/local/captive-portal/config.yaml
admin:
  username: "cpadmin"
  password: "123456"
database:
  uri: "sqlite:////usr/local/captive-portal/database.db"
captive_portal:
  ip: "192.168.1.2"
  port: 80
nginx:
  listen_port: 80
  server_name: "192.168.1.2"
EOF

# NGINX Yapılandırması
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

# NGINX ve PF Hizmetlerinin Başlatılması
echo "NGINX ve PF hizmetleri başlatılıyor..."
service nginx start
echo "net.inet.ip.forwarding=1" >> /etc/sysctl.conf
sysctl net.inet.ip.forwarding=1

# PF Konfigürasyonu
cat <<EOF > /etc/pf.conf
ext_if = "em0"
int_if = "em1"
captive_portal_ip = "192.168.1.2"

scrub in all
nat on \$ext_if from \$int_if:network to any -> (\$ext_if)

rdr on \$int_if proto tcp from any to any port 80 -> \$captive_portal_ip port 80
rdr on \$int_if proto tcp from any to any port 443 -> \$captive_portal_ip port 80

block all
pass in on \$int_if proto tcp from any to \$captive_portal_ip port 80
EOF

pfctl -f /etc/pf.conf
pfctl -e

# Flask Uygulamasının Başlatılması
echo "Flask uygulaması başlatılıyor..."
cat <<EOF > /etc/rc.local
#!/bin/sh
source /usr/local/captive-portal/venv/bin/activate
python /usr/local/captive-portal/app.py &
EOF
chmod +x /etc/rc.local
/etc/rc.local

echo "Kurulum tamamlandı!"
