echo -e "\n🚀 НАЧИНАЕМ: Установка, выпуск и импорт SSL для IP...\n"


echo "📦 Шаг 1: Установка acme.sh..."
cd ~
wget -qO master.tar.gz https://github.com/acmesh-official/acme.sh/archive/master.tar.gz
tar -zxf master.tar.gz
cd acme.sh-master
./acme.sh --install --force >/dev/null 2>&1
source ~/.acme.sh/acme.sh.env
cd ~
rm -rf ~/acme.sh-master ~/master.tar.gz


IP=$(curl -s ipv4.icanhazip.com)
echo "🌍 Шаг 2: Работаем с IP -> $IP"


echo "🛑 Шаг 3: Останавливаем Nginx и запрашиваем сертификат..."
synosystemctl stop nginx
~/.acme.sh/acme.sh --issue -d "$IP" \
  --standalone --httpport 80 \
  --server letsencrypt \
  --certificate-profile shortlived --force
ISSUE_STATUS=$?


echo "🟢 Запускаем Nginx обратно..."
synosystemctl start nginx

if [ $ISSUE_STATUS -eq 0 ]; then
    echo "✅ Шаг 4: Сертификат получен! Внедряем в систему..."
    
    export SYNO_Create=1
    export SYNO_USE_TEMP_ADMIN=1
    
    ~/.acme.sh/acme.sh --deploy -d "$IP" --deploy-hook synology_dsm
    
    if [ $? -eq 0 ]; then
        echo -e "\n🎉 ГОТОВО! Сертификат установлен. Проверяй Панель управления DSM!"
    else
        echo -e "\n❌ ОШИБКА: Сертификат получен, но не смог импортироваться в DSM."
    fi
else
    echo -e "\n❌ ОШИБКА: Let's Encrypt отказал в выдаче сертификата."
fi
