module "qa" {
    source = "../modules/blog"

    enviroment =  {
        name           = "qa"
        network_prefix = "10.1"
    }

    asg_min_size = 2
    asg_max_size = 2
}
