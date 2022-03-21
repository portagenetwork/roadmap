# frozen_string_literal: true

require "csv"

# DMPRoadmap constants
#
# This file is a consolidation of the old custom configuration previously spread
# across the application.rb, branding.yml and the contact_us, devise, recaptcha,
# constants and wicked_pdf initializers
#
# It works in conjunction with the new Rails 5 config/credentials.yml.enc file
# for information on how to use the credentials file see:
#    https://medium.com/cedarcode/rails-5-2-credentials-9b3324851336
#
# This file's name begins with an underscore so that it is processed first and its
# values are available to all other initializers within this directory!
# rubocop:disable Layout/LineLength
module DMPRoadmap

  class Application < Rails::Application

    # --------------------- #
    # ORGANISATION SETTINGS #
    # --------------------- #

    # Your organisation name, used in various places throught the application
    config.x.organisation.name = "Digital Research Alliance of Canada"
    # Your organisation's abbreviation
    config.x.organisation.abbreviation = "Portage"
    # Your organisation's homepage, used in some of the public facing pages
    config.x.organisation.url = "https://alliancecan.ca/"
    # Your organisation's legal (official) name - used in the copyright portion of the footer
    config.x.organisation.copywrite_name = "Digital Research Alliance of Canada"
    # This email is used as the 'from' address for emails generated by the application
    config.x.organisation.email = "info@alliancecan.ca"
    # This email is used as the 'from' address for the feedback_complete email to users
    config.x.organisation.do_not_reply_email "do-not-reply@alliancecan.ca"
    # This email is used in email communications
    config.x.organisation.helpdesk_email = "support@portage.org"
    # Your organisation's telephone number - used on the contact us page
    config.x.organisation.telephone = "+1-123-123-1234"
    # Your organisation's address - used on the contact us page
    config.x.organisation.address = {
      line_1: "P.O. Box 48008",
      line_2: "Davisville Post Office",
      line_3: "Toronto, ON",
      line_4: "M4S 3C6",
      country: "Canada"
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
    config.x.application.name = "DMP Assistant"
    # Used as the default domain when 'archiving' (aka anonymizing) a user account
    # for example `jane.doe@uni.edu` becomes `1234@removed_accounts-example.org`
    config.x.application.archived_accounts_email_suffix = "@removed_accounts-example.org"
    # Available CSV separators, the default is ','
    config.x.application.csv_separators = [",", "|", "#"]
    # The largest page size allowed in requests to the API (all versions)
    config.x.application.api_max_page_size = 100
    # The link to the API documentation - used in emails about the API
    config.x.application.api_documentation_urls = {
      v0: "https://github.com/DMPRoadmap/roadmap/wiki/API-V0-Documentation",
      v1: "https://github.com/DMPRoadmap/roadmap/wiki/API-Documentation-V1"
    }
    # The links that appear on the home page. Add any number of links
    config.x.application.welcome_links = [
      {
        title: "Digital Research Alliance of Canada",
        url: "https://alliancecan.ca/"
      }, {
        title: "DMP Online",
        url: "https://dmponline.dcc.ac.uk/about_us"
      }, {
        title: "Canadian Association of Research Libraries",
        url: "http://carl-abrc.ca/"
      }, {
        title: "University of Alberta Library",
        url: "https://www.library.ualberta.ca"
      }, {
        title: "University of California Curation Center",
        url: "https://cdlib.org/services/uc3"
      },
      {
        title: "Digital Curation Centre",
        url: "http://www.dcc.ac.uk"
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
    # Setting to only take orgs from local and not allow on-the-fly creation
    config.x.application.restrict_orgs = true

    # ------------------- #
    # SHIBBOLETH SETTINGS #
    # ------------------- #

    # Enable shibboleth as an alternative authentication method
    # Requires server configuration and omniauth shibboleth provider configuration
    # See config/initializers/devise.rb
    config.x.shibboleth.enabled = false

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
    config.x.locales.default = "en-CA"
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
    # default results per page
    config.x.results_per_page = 10

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
    config.x.plans.default_percentage_answered = 0

    # Whether or not Super adminis can read all of the user's plans regardless of
    # the plans visibility and whether or not the plan has been shared
    config.x.plans.org_admins_read_all = false
    # Whether or not Organisational administrators can read all of the user's plans
    # regardless of the plans visibility and whether or not the plan has been shared
    config.x.plans.super_admins_read_all = true

    # ---------------------------------------------------- #
    # CACHING - all values are in seconds (86400 == 1 Day) #
    # ---------------------------------------------------- #

    # Determines how long to cache results for OrgSelection::SearchService
    config.x.cache.org_selection_expiration = 86_400
    # Determines how long to cache results for the ResearchProjectsController
    config.x.cache.research_projects_expiration = 86_400

    # ---------------- #
    # Google Analytics #
    # ---------------- #
    # this is the abbreviation for the installation's root org as set in the org table
    config.x.google_analytics.tracker_root = ""

    # ------------------------------------------------------------------------ #
    # reCAPTCHA - recaptcha appears on the create account and contact us forms #
    # ------------------------------------------------------------------------ #
    config.x.recaptcha.enabled = true

    # --------------------------------------------------- #
    # Machine Actionable / Networked DMP Features (maDMP) #
    # --------------------------------------------------- #
    config.x.madmp.enable_ethical_issues = false
    config.x.madmp.enable_research_domain = false

  end

end
# rubocop:enable Layout/LineLength
