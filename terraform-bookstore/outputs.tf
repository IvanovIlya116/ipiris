output "ssh_connection_string" {
  value = "ssh -i ${path.module}/ssh_keys/id_rsa ipiris@${yandex_compute_instance.vm.network_interface.0.nat_ip_address}"
}

output "web_app_url" {
  value = "http://${yandex_compute_instance.vm.network_interface.0.nat_ip_address}"
}
