This updated script includes:

Port conflict resolution (using 9201, 5602 instead of default ports)
Proper repository setup
Service cleanup before installation
Port availability checks
Health checks for containers
UFW firewall configuration
Verification script

To run:
bashCopychmod +x setup_monitoring.sh
sudo ./setup_monitoring.sh
Access via:

Kibana: http://<yourIP>:5602
Elasticsearch: http://<yourIp>:9201
Username: elastic
Password: <setpassword>
