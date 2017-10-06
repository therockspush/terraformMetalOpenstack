# Compute node only below

# sanity check - make sure we can reach the controller
ping controller -c 5 -q
if [ $? -ne 0 ] ; then
  echo "controller is unreachable"
  echo "check /etc/hosts and networking and then restart this script"
  exit -1
fi

# private IP addr (10...)
MY_IP=`hostname -I | xargs -n1 | grep "^10\." | head -1`

apt -y install nova-compute

/etc/nova/nova.conf file and complete the following actions:

crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:RABBIT_PASS@controller


crudini --set /etc/nova/nova.conf api auth_strategy keystone

crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password NOVA_PASS


crudini --set /etc/nova/nova.conf DEFAULT my_ip = ${MY_IP}
crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

crudini --set /etc/nova/nova.conf vnc enabled True
crudini --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address ${MY_IP}
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://controller:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf glance api_servers http://controller:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

# Due to a packaging bug, remove the log_dir option from the [DEFAULT] section.
crudini --del /etc/nova/nova.conf DEFAULT log_dir


crudini --set /etc/nova/nova.conf placement os_region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://controller:35357/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password PLACEMENT_PASS

crudini --set /etc/nova/nova.conf libvirt virt_type kvm



# CPU Architecture Specific Settings

ARCH=`dpkg --print-architecture`

if [ $ARCH == amd64 ]; then
  echo "Configuring as an AMD64 compute host"
  # accept default
elif [ $ARCH == arm64 ]; then
  echo "Configuring as an ARM64 compute host"
  crudini --set /etc/nova/nova.conf vnc enabled False
  crudini --set /etc/nova/nova.conf spice enabled False 
  crudini --set /etc/nova/nova.conf libvirt virt_type kvm
  crudini --set /etc/nova/nova.conf libvirt cpu_mode host-passthrough
  
  crudini --set /etc/nova/nova.conf serial_console enabled true
  crudini --set /etc/nova/nova.conf serial_console base_url ws://controller:6083/
  crudini --set /etc/nova/nova.conf serial_console proxyclient_address ${MY_IP}
  crudini --set /etc/nova/nova.conf serial_console proxyclient_address listen=0.0.0.0 
fi



service nova-compute restart