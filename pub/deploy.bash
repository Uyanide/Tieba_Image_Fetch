pm2_proc_name="tif-version"
pm2_app_file="version_service.js"

if [ -n "$(pm2 list | grep $pm2_proc_name)" ]; then
    echo "Service is running, stopping it..."
    pm2 stop $pm2_proc_name
    pm2 del $pm2_proc_name
    pm2 save
fi

pm2 start $pm2_app_file --name $pm2_proc_name
pm2 save