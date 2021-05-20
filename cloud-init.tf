data "template_cloudinit_config" "config" {
    gzip = true
    base64_encode = true

    part {
        filename = "terraform.tpl"
        content_type = "text/cloud-config"
        content = templatefile("${path.module}/cloudinit/01-init.tpl", {
            instance = var.instance_name,
            domain = "${var.instance_name}.${var.rootdomain}",
            ssh_users = var.ssh_users
        })
    }
    part {
        content_type = "text/x-shellscript"
        content = templatefile("${path.module}/cloudinit/02-configure.sh.tpl", {
            hostname = "${var.instance_name}.${var.rootdomain}",
            ssh_users = var.ssh_users
        })
    }
}