variable "vpc_name" {
  description = "Name tag prefix for database resources"
  type        = string
  default     = "cl-01"
}

variable "private_db_subnet_ids" {
  description = "List of private subnet IDs for the database"
  type        = list(string)
}

variable "database_sg_id" {
  description = "Security Group ID for the database"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "apidata"
}

variable "db_master_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "db_engine" {
  description = "The database engine to use"
  type        = string
  default     = "aurora-postgresql"
}

variable "db_engine_mode" {
  description = "The database engine mode"
  type        = string
  default     = "provisioned"
}

variable "db_engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "15.4" # Or whatever version your friend used, 15.4 is stable for Aurora Serverless v2
}

variable "db_instance_class" {
  description = "The instance class for the database"
  type        = string
  default     = "db.serverless"
}