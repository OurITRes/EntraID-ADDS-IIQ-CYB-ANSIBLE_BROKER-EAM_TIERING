
resource "azuread_group" "dyn_t1_prd" {
  display_name                   = "GRP-DYN-T1-PRD-Users"
  description                    = "Dynamic group: users with TIER=T1 and ENV=PRD"
  security_enabled               = true
  assignable_to_role             = false
  mail_enabled                   = false
  types                          = ["DynamicMembership"]
  dynamic_membership {
    enabled = true
    rule    = "(user.extensionAttribute10 -eq \"T1\") and (user.extensionAttribute11 -eq \"PRD\")"
  }
}
