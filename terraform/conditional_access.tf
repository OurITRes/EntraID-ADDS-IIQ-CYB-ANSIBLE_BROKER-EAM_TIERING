
# NOTE: Example resource name; adapt to your chosen provider supporting CA
resource "microsoft365_conditional_access_policy" "pim_paw_only" {
  display_name = "CA-PIM-Activation-PAW-Only"
  state        = "enabled"
  conditions {
    users {
      included_groups = [azuread_group.dyn_t1_prd.id]
    }
    applications {
      include_user_actions = ["urn:user:registersecurityinfo"]
    }
    client_app_types = ["browser","mobileAppsAndDesktopClients"]
    platforms {
      include_platforms = ["all"]
    }
    device_states {
      include_states = ["compliant"]
    }
  }
  grant_controls {
    operator            = "AND"
    built_in_controls   = ["mfa","compliantDevice"]
  }
  session_controls {
    application_enforced_restrictions_enabled = true
  }
}
