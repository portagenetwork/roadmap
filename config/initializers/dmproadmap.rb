# frozen_string_literal: true

require "csv"

# DMPRoadmap constants #
module DMPRoadmap

  class Application < Rails::Application

    # --------------------- #
    # ORGANISATION SETTINGS #
    # --------------------- #

    # Your organisation name, used in various places throught the application
    config.x.organisation.name = "Curation Center"
    # Your organisation's abbreviation
    config.x.organisation.abbreviation = "CC"
    # Your organisation's homepage, used in some of the public facing pages
    config.x.organisation.url = "https://github.com/DMPRoadmap/roadmap/wiki"
    # Your organisation's legal (official) name - used in the copyright portion of the footer
    config.x.organisation.copywrite_name = "Curation Centre (CC)"
    # This email is used as the 'from' address for emails generated by the application
    config.x.organisation.email = "tester@example.org"
    # This email is used in email communications
    config.x.organisation.helpdesk_email = "help@example.org"
    # Your organisation's telephone number - used on the contact us page
    config.x.organisation.telephone = "+1-123-123-1234"
    # Your organisation's address - used on the contact us page
    config.x.organisation.address = {
      line_1: "Princess Elisabeth Station",
      line_2: "123 Freezing Cold Street",
      line_3: "Suite 123",
      line_4: "Polar Vortex, ABC-345",
      country: "Antarctica"
    }

    # The Google maps link to your organisation's location - used to display the
    # Google map on the contact us page.
    # To find your organisation's Google maps URL, open maps.google.com, search for
    # your orgnaisation and then click the menu link to the left of the search box,
    # once the menu opens, click the 'share or embed' link and the 'embed' tab on
    # the dialog window that opens. DO NOT place the entire <iframe> tag below, just
    # the address!
    config.x.organisation.google_maps_link = "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d29046286.09795864!2d-34.22768319424708!3d-63.61874004304689!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0xb57520cc078b16a9!2sPrincess%20Elisabeth%20Station!5e0!3m2!1sen!2sus!4v1587495708129!5m2!1sen!2sus"

    # Uncomment the following line if you want to redirect your users to an
    # organisational contact/help page instead of using the built-in contact_us form
    # config.x.organisation.contact_us_url = "https://example.org/contact

    # -------------------- #
    # APPLICATION SETTINGS #
    # -------------------- #

    # Used throughout the system via ApplicationService.application_name
    config.x.application.name = "DMPRoadmap"
    # Used as the default domain when 'archiving' (aka anonymizing) a user account
    # for example `jane.doe@uni.edu` becomes `1234@removed_accounts-example.org`
    config.x.application.archived_accounts_email_suffix = "@removed_accounts-example.org"
    # Available CSV separators, the default is ','
    config.x.application.csv_separators = [",", "|", "#"]
    # The largest page size allowed in requests to the API (all versions)
    config.x.application.api_max_page_size = 100
    # The link to the API documentation - used in emails about the API
    config.x.application.api_documentation_url = "https://github.com/DMPRoadmap/roadmap/wiki/API-Documentation"
    # The links that appear on the home page. Add any number of links
    config.x.application.welcome_links = [
      {
        title: "Digital Curation Centre",
        url: "https://dcc.ac.uk/"
      }, {
        title: "UC3: University of California Curation Center",
        url: "https://www.cdlib.org/uc3/"
      }, {
        title: "UK funder requirements for Data Management Plans",
        url: "http://www.dcc.ac.uk/resources/data-management-plans/funders-requirements"
      }, {
        title: "US funder requirements for Data Management Plans",
        url: "https://dmptool.org/guidance"
      }, {
        title: "DCC Checklist for a Data Management Plan",
        url: "https://dmponline.dcc.ac.uk/files/DMP_Checklist_2013.pdf"
      }
    ]
    # The default user email preferences used when a new account is created
    config.x.application.preferences = {
      email: {
        users: {
          new_comment: false,
          admin_privileges: true,
          added_as_coowner: true,
          feedback_requested: true,
          feedback_provided: true
        },
        owners_and_coowners: {
          visibility_changed: true
        }
      }
    }

    # ------------------- #
    # SHIBBOLETH SETTINGS #
    # ------------------- #

    # Enable shibboleth as an alternative authentication method
    # Requires server configuration and omniauth shibboleth provider configuration
    # See config/initializers/devise.rb
    config.x.shibboleth.enabled = true

    # Relative path to Shibboleth SSO Logouts
    config.x.shibboleth.login_url = "/Shibboleth.sso/Login"
    config.x.shibboleth.logout_url = "/Shibboleth.sso/Logout?return="

    # If this value is set to true your users will be presented with a list of orgs that have a
    # shibboleth identifier in the orgs_identifiers table. If it is set to false (default), the user
    # will be driven out to your federation's discovery service
    #
    # A super admin will also be able to associate orgs with their shibboleth entityIds if this is set to true
    config.x.shibboleth.use_filtered_discovery_service = false

    # ------- #
    # LOCALES #
    # ------- #

    # The default locale (use the i18n format!)
    config.x.locales.default = "en-GB"
    # The character that separates a locale's ISO code for i18n. (e.g. `en-GB` or `en`)
    # Changing this value is not recommended!
    config.x.locales.i18n_join_character = "-"
    # The character that separates a locale's ISO code for Gettext. (e.g. `en_GB` or `en`)
    # Changing this value is not recommended!
    config.x.locales.gettext_join_character = "_"


    # ---------- #
    # THRESHOLDS #
    # ---------- #

    # Determines the number of links a funder is allowed to add to their template
    config.x.max_number_links_funder = 5
    # Determines the number of links a funder can add for sample plans for their template
    config.x.max_number_links_sample_plan = 5
    # Determines the maximum number of themes to display per column when an org admin
    # updates a template question or guidance
    config.x.max_number_themes_per_column = 5

    # ------------- #
    # PLAN DEFAULTS #
    # ------------- #

    # The default visibility a plan receives when it is created.
    # options: 'privately_visible', 'organisationally_visible' and 'publicly_visibile'
    config.x.plans.default_visibility = "privately_visible"

    # The percentage of answers that have been filled out that determine if a plan
    # will be marked as complete. Plan completion has implications on whether or
    # not plan visibility settings are editable by the user and whether or not the
    # plan can be submitted for feedback
    config.x.plans.default_percentage_answered = 50

    # Whether or not Super adminis can read all of the user's plans regardless of
    # the plans visibility and whether or not the plan has been shared
    config.x.plans.org_admins_read_all = true
    # Whether or not Organisational administrators can read all of the user's plans
    # regardless of the plans visibility and whether or not the plan has been shared
    config.x.plans.super_admins_read_all = true

  end

end
