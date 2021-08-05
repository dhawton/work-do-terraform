data "template_cloudinit_config" "config" {
    gzip = false
    base64_encode = false

    part {
        filename = "terraform.tpl"
        content_type = "text/cloud-config"
        content = templatefile("${path.module}/../cloudinit/01-init.tpl", {
            ssh_users = var.ssh_users
        })
    }
    part {
        content_type = "text/x-shellscript"
        content = templatefile("${path.module}/../cloudinit/02-configure.sh.tpl", {
            hostname = "",
            ssh_users = var.ssh_users
            install_docker = var.install_docker
        })
    }
}