data "template_cloudinit_config" "config" {
    gzip = false
    base64_encode = false

    part {
        filename = "terraform.tpl"
        content_type = "text/cloud-config"
        content = templatefile("${path.module}/cloudinit/01-init.tpl", {
            instance = var.instance_name,
            domain = "${var.instance_name}.${var.rootdomain}",
            ssh_users = var.ssh_users,
            debian_testing = var.instance_testing,
            debugging = var.debugging
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