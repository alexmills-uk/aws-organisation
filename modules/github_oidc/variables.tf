variable "allowed_repositories" {
    type = list(string)
    description = "A list of GitHub repositories that are allowed to assume this AWS role. Must be in the format {organisation/username}/{repository}:{branch}."
}