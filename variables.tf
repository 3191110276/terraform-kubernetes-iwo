############################################################
# INPUT VARIABLES
############################################################
variable "namespace" {
  type        = string
  default     = "iwo"
  description = "Namespace used for deploying the IWO objects. This namespace has to exist and is not provisioned by this module"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster in Intersight. Has to be unique per Intersight instance."
}

variable "iwo_server_version" {
  type        = string
  default     = "8.0"
  description = "Version of the IWO server. Default can be used in most cases."
}
