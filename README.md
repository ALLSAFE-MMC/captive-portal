# Captive Portal

Bu proje, FreeBSD üzerinde çalışan ve MERNİS kimlik doğrulaması ile 5651 sayılı kanuna uygun loglama ve imzalama özelliklerine sahip bir captive portal uygulamasıdır.

## Kurulum

### Gerekli Dosyaların İndirilmesi ve Kurulumu

Kurulumdan önce `/usr/local/captive-portal/config.yaml` dosyasını ihtiyaçlarınıza göre düzenleyin:

```yaml
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
