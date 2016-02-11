etcd_discovery_url.txt:
	curl -s https://discovery.etcd.io/new?size=3 > etcd_discovery_url.txt

plan: etcd_discovery_url.txt
	terraform plan

apply: etcd_discovery_url.txt
	terraform apply

destroy:
	terraform destroy
	rm etcd_discovery_url.txt

