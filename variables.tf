############################################################
# INPUT VARIABLES
############################################################
variable "namespace" {
  type        = string
  default     = "iwo"
  description = "Namespace used for deploying the IWO objects. This namespace has to exist and is not provisioned by this module."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Determines if a Kubernetes namespace should be created as part of the IWO setup."
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster in Intersight. Has to be unique per Intersight instance."
}

variable "iwo_server_version" {
  type        = string
  default     = "8"
  description = "Version of the IWO server. Default can be used in most cases."
}

variable "dc_version" {
  type        = string
  default     = "1.0.9-1"
  description = "Version of the device connector used for establishing the Intersight tunnel. Default can be used in most cases."
}

variable "collector_version" {
  type        = string
  default     = "8.0.1"
  description = "Version of the collector used for gathering data from the local Kubernetes cluster. Default can be used in most cases."
}

variable "configure_proxy" {
  type        = bool
  default     = false
  description = "Should be set to true if a the connection to Intersight requires a proxy for communication."
}
