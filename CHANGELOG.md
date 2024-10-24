# Changelog

## [Unreleased]

### Changed

 - Email Confirmation Changes [#923](https://github.com/portagenetwork/roadmap/pull/923)

 - Disable Updating of User Emails [#917](https://github.com/portagenetwork/roadmap/pull/917)

### Fixed

 - Fix User Lookup Via SSO Email: Make Query Case-Insensitive [#924](https://github.com/portagenetwork/roadmap/pull/924)

 - Fixes to CILogon / `openid_connect` Tests [#922](https://github.com/portagenetwork/roadmap/pull/922)

## [4.1.1+portage-4.2.2] - 2024-09-18

### Changed

 - Update Handling of SSO Linking [#907](https://github.com/portagenetwork/roadmap/pull/907)
 
 - Updated SSO button string [portagenetwork/roadmap#903](https://github.com/portagenetwork/roadmap/issues/903)

## [4.1.1+portage-4.2.1] - 2024-09-12

### Changed

 - Patch to allow multiple hosts when setting config of some environments [#899](https://github.com/portagenetwork/roadmap/pull/899)

## [4.1.1+portage-4.2.0] - 2024-09-11

### Added

 - Add Rake Upgrade Task For `4.1.1+portage-4.2.0` [#892](https://github.com/portagenetwork/roadmap/pull/892)

 - Test cases for CILogon(openid_connection) changes in Omniauth controller - [#869](https://github.com/portagenetwork/roadmap/pull/869/)

 - Implemented openid_connection SSO with CILogon [#872](https://github.com/portagenetwork/roadmap/pull/872)

 - Create GET "/api/ca_dashboard/stats" endpoint to fetch Plan, User, and Org-related statistics [#852](https://github.com/portagenetwork/roadmap/pull/852)
 
 - Added SSO changes updates to the About and Help pages. [#882](https://github.com/portagenetwork/roadmap/pull/882)

### Changed

 - Update Favicons and Associated HTML Code [#873](https://github.com/portagenetwork/roadmap/pull/873)

 - Drop Sessions Table and Delete `lib/tasks/sessions.rake` [#859](https://github.com/portagenetwork/roadmap/pull/859)

 - Optimise Load Time of "Edit Profile" Page [#883](https://github.com/portagenetwork/roadmap/pull/883)

 - Update ruby workflow command for executing tests [#896](https://github.com/portagenetwork/roadmap/pull/896)

### Fixed

 - Fix triggering and title of autosent email when a user's admin privileges are changed [#858](https://github.com/portagenetwork/roadmap/pull/858)

 - Fix flaky tests / Optimize Checking Of `plan.title` Within `spec/features/plans/exports_spec.rb` [#871](https://github.com/portagenetwork/roadmap/pull/871)

 - Patch to Put Back ORCID Linking Functionality [#891](https://github.com/portagenetwork/roadmap/pull/891)

## [4.1.1+portage-4.1.3] - 2024-08-08

### Changed

 - Bump rexml from 3.2.8 to 3.3.3 [#839](https://github.com/portagenetwork/roadmap/pull/839)

 - Update "Welcome" and "About" Pages For Alliance Rebrand [#844](https://github.com/portagenetwork/roadmap/pull/844)

### Fixed

 - Remove Vulnerable ws@8.11.0 Dependency by Upgrading `karma` [#841](https://github.com/portagenetwork/roadmap/pull/841)

## [4.1.1+portage-4.1.2] - 2024-07-24

### Changed

 - Use "id" instead of "name" for `default_funder` Org [#814](https://github.com/portagenetwork/roadmap/pull/814)

 - Bump jwt from 2.7.1 to 2.8.2 [#803](https://github.com/portagenetwork/roadmap/pull/803)

 - Bump cssbundling-rails from 1.3.3 to 1.4.0 [#796](https://github.com/portagenetwork/roadmap/pull/796)

 - Bump devise from 4.9.3 to 4.9.4 [#822](https://github.com/portagenetwork/roadmap/pull/822)

 - Bump omniauth-rails_csrf_protection from 1.0.1 to 1.0.2 [#802](https://github.com/portagenetwork/roadmap/pull/802)

 - Bump pundit from 2.3.1 to 2.3.2 [#786](https://github.com/portagenetwork/roadmap/pull/786)

 - Bump rollbar from 3.5.1 to 3.5.2 [#784](https://github.com/portagenetwork/roadmap/pull/784)

 - Bump socket.io from 4.6.1 to 4.7.5 [#804](https://github.com/portagenetwork/roadmap/pull/804)

 - Bump tinymce from 7.0.0 to 7.2.0 [#801](https://github.com/portagenetwork/roadmap/pull/801)

## [4.1.1+portage-4.1.0] - 2024-07-08, [4.1.1+portage-4.1.1] - 2024-07-09

### Added

 - Merge DMPRoadmap Releases v4.1.0 and v4.1.1 [#700](https://github.com/portagenetwork/roadmap/pull/700)

 - Enable Translation of QuestionOption.text (and Refactor Translation of ResearchDomain.label) [#742](https://github.com/portagenetwork/roadmap/pull/742)

### Fixed

 - Set `licence_key` in TinyMCE config [#792](https://github.com/portagenetwork/roadmap/pull/792)

 - Add .pdf handling in render_respond_to_format_with_error_message [#731](https://github.com/portagenetwork/roadmap/pull/731)

 - Fixed handling of Template.visibility in some places [#759](https://github.com/portagenetwork/roadmap/pull/759)

### Changed

 - Deactivate Requests to External ROR API [#738](https://github.com/portagenetwork/roadmap/pull/738)

 - Updated 'translation' gem URL in Gemfile to match moved repository [#725](https://github.com/portagenetwork/roadmap/pull/725)

 - Increased the width of the research outputs file size unit dropdown [#741](https://github.com/portagenetwork/roadmap/pull/741)

 - Bump ledermann-rails-settings from 2.5.0 to 2.6.2 [#764](https://github.com/portagenetwork/roadmap/pull/764)

 - Bump webmock from 3.19.1 to 3.23.1 [#762](https://github.com/portagenetwork/roadmap/pull/762)

 - Bump rspec-rails from 6.0.3 to 6.1.2 [#694](https://github.com/portagenetwork/roadmap/pull/694)
 
 - Bump docker db image from postgres:12.14 to postgres:15-alpine [#749](https://github.com/portagenetwork/roadmap/pull/749)

 - Bump danger from 9.4.2 to 9.4.3 [#681](https://github.com/portagenetwork/roadmap/pull/681)

 - Bump mail from 2.7.1 to 2.8.1 [#651](https://github.com/portagenetwork/roadmap/pull/651)

 - Bump turbo-rails from 1.5.0 to 2.0.5 [#771](https://github.com/portagenetwork/roadmap/pull/771)

 - Bump jbuilder from 2.11.5 to 2.12.0 [#770](https://github.com/portagenetwork/roadmap/pull/770)

 - Bump faker from 3.2.3 to 3.4.1 [#769](https://github.com/portagenetwork/roadmap/pull/769)

 - Bump jsbundling-rails from 1.1.1 to 1.3.0 [#768](https://github.com/portagenetwork/roadmap/pull/768)

 - Bump binding_of_caller from 1.0.0 to 1.0.1 [#767](https://github.com/portagenetwork/roadmap/pull/767)

 - Bump engine.io from 6.4.1 to 6.4.2 [#774](https://github.com/portagenetwork/roadmap/pull/774)

 - Bump activestorage from 6.1.7.6 to 6.1.7.7 [#773](https://github.com/portagenetwork/roadmap/pull/773)

 - Bump @babel/traverse from 7.21.4 to 7.24.6 [#772](https://github.com/portagenetwork/roadmap/pull/772)

 - Bump follow-redirects from 1.15.4 to 1.15.6 [#690](https://github.com/portagenetwork/roadmap/pull/690)

 - Bump devise_invitable from 2.0.8 to 2.0.9 [#671](https://github.com/portagenetwork/roadmap/pull/671)
 
 - Bump yard from 0.9.34 to 0.9.36 [#683](https://github.com/portagenetwork/roadmap/pull/683)

 - Bump tinymce from 6.4.1 to 7.0.0 [#704](https://github.com/portagenetwork/roadmap/pull/704)

 - Bump actionpack from 6.1.7.7 to 6.1.7.8 [#775](https://github.com/portagenetwork/roadmap/pull/775)

 - Bump brakeman from 5.4.1 to 6.1.2 [#781](https://github.com/portagenetwork/roadmap/pull/781)

 - Bump wkhtmltopdf-binary from 0.12.6.6 to 0.12.6.7 [#779](https://github.com/portagenetwork/roadmap/pull/779)

 - Bump rack-mini-profiler from 3.3.0 to 3.3.1 [#778](https://github.com/portagenetwork/roadmap/pull/778)

 - Bump listen from 3.8.0 to 3.9.0 [#776](https://github.com/portagenetwork/roadmap/pull/776)

 - Bump braces from 3.0.2 to 3.0.3 [#795](https://github.com/portagenetwork/roadmap/pull/795)

 - Bump Ruby from 3.0.4 to 3.1.4 [#808](https://github.com/portagenetwork/roadmap/pull/808)

## V4.1.1

### Added
- Added `MORE_INFO` and `LESS_INFO` JS constants (for the Research Outputs feature)
- Added a .gitkeep file to the app/assets/builds directory to address potential issues when building the application.css file during production deploys #3314

### Fixed
- Updated the default font on the 'Download page' to be 'Roboto, Arial, Sans-Serif'
- Fixed an issue with API V0 that was causing a 500 Internal Server error
- Solved issue where spring was loaded in production mode : ran `bin/spring binstub --all`
- Updated fontawesome to V6

## v4.1.0

**Note this upgrade is a migration from Ruby v2.7.6 to v3.0.5.** Note that this could have an impact on any customizations you may have made to your fork of this project. Please see https://www.fastruby.io/blog/ruby/upgrades/upgrade-ruby-from-2.7-to-3.0.html for further information on what to check. In particular, please note the changes to the way [Ruby 3 handles keyword arguments](https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/)

**Note that the Webpacker gem has been removed in favor of jsbundling-rails.** This was done in preparation for the future migration to Rails 7. See [issue #3185](https://github.com/DMPRoadmap/roadmap/issues/3185) for more details on this change. If, after migrating to this version, you see 'Sprockets' related errors in your application you will need to rebuild you asset library. To do this run `bin/rails assets:clobber && bin/rails assets:precompile` from the project directory.

All gem and JS dependencies were also updated via `bundle update && yarn upgrade`

### Upgrade to Ruby 3

- Upgrade to Ruby version 3.0.5 [#3225](https://github.com/DMPRoadmap/roadmap/issues/3225)
- Bumped all Github actions to use ruby 3.0
- Removed `.freeze` from Regex and Range constants since those types are already immutable
- Fixed Rubocop complaint about redundancy of `r.nil? ? nil : r.user`, so changed it to `r&.user` in `app/models/plan.rb`
- Fixed Rubocop complaint about redundant `::` in config.log_formatter = `::Logger::Formatter.new` in `config/environments/production.rb`
- Froze `lib/deprecators/*.rb` constants that were Strings
- Updated places that were incorrectly using keyword args. See [this article](https://makandracards.com/makandra/496481-changes-to-positional-and-keyword-args-in-ruby-3-0) for an overview

#### Upgraded TinyMCE to v6

- Upgraded TinyMCE to v6 (v5 EOL is April 20 2023)
- Adjusted JS code to conform to new TinyMCE version
- Adjusted views to work with the new version
- Updated variables.scss file to fix issue with button text/background color contrast
- Updated blocks/_tables.scss to fix issue with dropdown menu overlap against table
- updated config/initializers/assets.rb to copy over the tinymce skins and bootstrap glyphicons to the public directory so that they are accessible by TinyMCE and Bootstrap code

#### Removed webpacker gem

As Webpacker is no longer maintained by the Rails community, we have replaced it by `jsbundling-rails` and `cssbundling-rails` for the Javascript & CSS compilation.

- Removed `webpacker` gem
- Added `jsbundling-rails`
- Updated webpack and its configuration to V5
- Moved `app/javascript/packs/application.js` to `app/javascript/application.js`
- Removed `ruby-sass` gem
- Added `cssbundling-rails` gem and DartSass JS library
- Updated SASS stylesheets following the migration to the latest version of the `sass` package (See below).
- Removed `font-awesome-sass` gem and used `@fortawesome/fontawesome-free` npm package
- Issue with `@import 'font-awesome-sprockets';` line in `app/assets/stylesheets/application.scss`. Removed that line after referring to the latest font-awesome install/setup guide which no longer includes it.

With the removal of Webpacker, the Javascript/SASS code is no longer automaticaly compiled when using the `rails server` command. It has been replaced by the `bin/dev` command that launch the rails server and the processes that watch for changes in the SASS and Javascript code.

#### SASS update : removal of the `@import` keyword

With the removal of the webpacker gem, the DartSass package has been installed to ensure the compilation of the Sass stylesheet and with it, an update to the Sass version used by the code :
- `@import` keyword for custom stylesheets has been removed (although we can still import stylesheets from externals packages) and has been replaced by `@use` and `@forward`
- An `_index.scss` file have to be created in folders containing multiple sass files. Each file have to be included in the index with the `@use` or `@forward` keyword.
- In most cases `@import` can be replaced by `@use` when importing a file.
- `@forward` makes mixins, functions and variables available when a stylesheet is loaded.
- When imported, Sass variables are now namespaced with the file name in which they are declared (ex : `color: colors.$red`). A namespace can be renamed (ex : `@use "colours" as c;`) or removed when included (ex : `@use "colours" as *;`)
- Sass variables are no longer declared globally and have to be included in files where they are used.
For more detailed explanation, please refer to this video : https://www.youtube.com/watch?v=CR-a8upNjJ0

### Introduction of RackAttack
[Rack Attack](https://github.com/rack/rack-attack) is middleware that can be used to help protect the application from malicious activity. You can establish white/black lists for specific IP addresses and also define rate limits.

- Using Rack-attack address vulnerabilities pointed out in password reset and login: there was no request rate limit.[#3214](https://github.com/DMPRoadmap/roadmap/issues/3214)

### Cleanup of Capybara configuration
- Cleaned up Gemfile by:
  - removing gems that were already commented out
  - removed selenium-webdriver and capybara-webmock
  - removing version restrictions on: danger, font-awesome-sass, webdrivers
- Cleaned up `spec/rails_helper.rb` and `spec/spec_helper.rb`
- Simplified the `spec/support/capybara.rb` helper to work with the latest version of Capybara and use its built in headless Chrome driver

### Rubocop updates
- Installed rubocop-performance gem and made suggested changes
- Added lib tasks as exclusive from debugger rubocop check after rubocop upgrading to >= v1.45 [#3291](https://github.com/DMPRoadmap/roadmap/issues/3291)

### GitHub actions updates
- Added node version specification (v16) to eslint, PostgreSQL and MySQL github action to eliminate `digital routine enveloped` error [#319](https://github.com/portagenetwork/roadmap/issues/319)

### Enhancements
- Added enum to the funding status attribute of plan model to make the dropdown of 'funding status' being translatable
- Allow users to download both single phase and  in PDF, TEXT and DOCX format. CSV file can only download single phase instead of all phases.

### Bug Fixes

## [4.0.2+portage-4.0.4] - 2024-05-15

### Fixed

 - Fixed an issue that was preventing users from accessing some customisable templates [#751](https://github.com/portagenetwork/roadmap/pull/751)

## [4.0.2+portage-4.0.3] - 2024-04-11

### Added

 - Bump mysql2 from 0.5.5 to 0.5.6 [#645](https://github.com/portagenetwork/roadmap/pull/645)

 - Added "Accept terms and conditions" checkbox to invitation form [#684](https://github.com/portagenetwork/roadmap/pull/684)

 - Bump rack from 2.2.8 to 2.2.9 [#714](https://github.com/portagenetwork/roadmap/pull/714)

 - Bump tar from 6.1.13 to 6.2.1 [#719](https://github.com/portagenetwork/roadmap/pull/719)

### Fixed

 - Updated Webmock's allowed request list to enable fetching of chromedriver [#670](https://github.com/portagenetwork/roadmap/pull/670)

 - Edit Gemfile config for 'rollbar' to enable app tracking on rollbar.com [#687](https://github.com/portagenetwork/roadmap/pull/687)

 - Fixed ordering of templates within the "Create a new plan" template dropdown [#706](https://github.com/portagenetwork/roadmap/pull/706) and [#718](https://github.com/portagenetwork/roadmap/pull/718)

## [4.0.2+portage-4.0.2] - 2024-03-04

### Added

 - Added an extra Google Analytics Tag [#682](https://github.com/portagenetwork/roadmap/pull/682)

## [4.0.2+portage-4.0.0] [4.0.2+portage-4.0.1] - 2024-02-01

### Added

 - Bump bootsnap from 1.17.1 to 1.18.3 [#630](https://github.com/portagenetwork/roadmap/pull/630)

 - Bump bullet from 7.1.5 to 7.1.6 [#605](https://github.com/portagenetwork/roadmap/pull/605)

 - Bump rollbar from 3.5.0 to 3.5.1 [#601](https://github.com/portagenetwork/roadmap/pull/601)

 - Bump faker from 3.2.2 to 3.2.3 [#603](https://github.com/portagenetwork/roadmap/pull/603)
 
 - Bump bootsnap from 1.17.0 to 1.17.1 [#598](https://github.com/portagenetwork/roadmap/pull/598)

 - Enabled reCaptcha widget's language to match app's selected language [#558](https://github.com/portagenetwork/roadmap/pull/558)

 - Bump follow-redirects from 1.15.2 to 1.15.4 [#596](https://github.com/portagenetwork/roadmap/pull/596)

 - Bump puma from 6.4.1 to 6.4.2 [#592](https://github.com/portagenetwork/roadmap/pull/592)

 - Bump puma from 6.4.0 to 6.4.1 [#584](https://github.com/portagenetwork/roadmap/pull/584)

 - Bump bullet from 7.1.4 to 7.1.5 [#588](https://github.com/portagenetwork/roadmap/pull/588)

 - Bump rollbar from 3.4.2 to 3.5.0 [#585](https://github.com/portagenetwork/roadmap/pull/585)

 - Bump parallel from 1.23.0 to 1.24.0 [#574](https://github.com/portagenetwork/roadmap/pull/574)

 - Bump omniauth from 2.1.1 to 2.1.2 [#573](https://github.com/portagenetwork/roadmap/pull/573)

 - Bump autoprefixer-rails from 10.4.15.0 to 10.4.16.0 [#571](https://github.com/portagenetwork/roadmap/pull/571)

 - Bump bootsnap from 1.16.0 to 1.17.0 [#564](https://github.com/portagenetwork/roadmap/pull/564)

 - Bump faker from 3.2.1 to 3.2.2 [#565](https://github.com/portagenetwork/roadmap/pull/565)

 - Bump turbo-rails from 1.4.0 to 1.5.0 [#566](https://github.com/portagenetwork/roadmap/pull/566)

 - Bump activerecord-nulldb-adapter from 0.9.0 to 1.0.1 [#567](https://github.com/portagenetwork/roadmap/pull/567)

 - Bump recaptcha from 5.15.0 to 5.16.0 [#568](https://github.com/portagenetwork/roadmap/pull/568)

 - Bump tinymce from 5.10.0 to 5.10.9 [#530](https://github.com/portagenetwork/roadmap/pull/530)

 - Bump rack-mini-profiler from 3.1.0 to 3.3.0 [#548](https://github.com/portagenetwork/roadmap/pull/548)

 - Bump spring from 4.1.1 to 4.1.3 [#562](https://github.com/portagenetwork/roadmap/pull/562)

 - Bump rollbar from 3.4.0 to 3.4.2 [#547](https://github.com/portagenetwork/roadmap/pull/547)

 - Bump danger from 9.3.1 to 9.4.2 [#555](https://github.com/portagenetwork/roadmap/pull/555)

 - Bump bullet from 7.1.0 to 7.1.4 [#563](https://github.com/portagenetwork/roadmap/pull/563)

 - Bump browserify-sign from 4.2.1 to 4.2.2 [#520](https://github.com/portagenetwork/roadmap/pull/520)

 - Bump socket.io-parser from 4.2.2 to 4.2.4 [#559](https://github.com/portagenetwork/roadmap/pull/559)

 - Merged Upstream Release [v4.0.0](https://github.com/DMPRoadmap/roadmap/releases/tag/v4.0.0)

 - Merged Upstream Release [v4.0.1](https://github.com/DMPRoadmap/roadmap/releases/tag/v4.0.1)

 - Merged Upstream Release [v4.0.2](https://github.com/DMPRoadmap/roadmap/releases/tag/v4.0.2)

### Fixed

 - Removed unwanted text from success notification when permissions are changed for a plan collaborator [#606](https://github.com/portagenetwork/roadmap/issues/606)

 - Fixed `gem install bundler` issue that was preventing Github Actions from pushing images to Docker Hub [#599](https://github.com/portagenetwork/roadmap/issues/599)

 - Fixed tooltips that were previously rendering 'undefined' as their message [#552](https://github.com/portagenetwork/roadmap/issues/552)

 - Patched a validation check to enable updates for all existing DMP Assistant Orgs [#587](https://github.com/portagenetwork/roadmap/issues/587)

 - Fix duplicate guidance choices [#560](https://github.com/portagenetwork/roadmap/issues/560)

 - Fix 500 error being thrown for GET api/v0/plans [#569](https://github.com/portagenetwork/roadmap/issues/569)

### Changed

 - Removed dmp-pgd.ca/?locale=fr_CA links from terms & privacy pages (they had no effect on the app's language selector) [#455](https://github.com/portagenetwork/roadmap/issues/455)

 - Updated ruby.yml workflow to use PostgreSQL database [#532](https://github.com/portagenetwork/roadmap/issues/532)

 - Added scss files to EditorConfig
 
 - Change csv file name for statistics from 'Completed' to 'Created'
 
 - Added error message and updated saving message for plan writing session to improve user experience

 ## v4.0.2

### Added
- Added CHANGELOG.md and Danger Github Action [#3257](https://github.com/DMPRoadmap/roadmap/issues/3257)
- Added validation with custom error message in research_output.rb to ensure a user does not enter a very large value as 'Anticipated file size'. [#3161](https://github.com/DMPRoadmap/roadmap/issues/3161)
- Added popover for org profile page and added explanation for public plan
- Added rack-attack version 6.6.1 gem. https://rubygems.org/gems/rack-attack/versions/6.6.1

### Fixed
- Fixed an issue that was preventing uses from leaving the research output byte_size field blank
- Patched issue that was causing template visibility to default to organizationally visible after saving
- Froze mail gem version [#3254](https://github.com/DMPRoadmap/roadmap/issues/3254)
- Updated the CSV export so that it now includes research outputs
- Updated sans-serif font used in PDF downloads to Roboto since Google API no longer offers Helvetica
- Fixed discrepencies with default/max per_page values for API and UI pagination
- Updated JS that used to call the TinyMCE `setMode()` function so that it now calls `mode.set()` because the former is now deprecated.
- Patched an issue that was causing a template's visibility to change to 'organizationally_visible' when saving on the template details page.
- Fixed an issue with the Rails 6 keyword arguments change that was causing the `paginable_sort_link` to fail
       
## [3.3.1+portage-3.2.2] - 2023-11-20

### Fixed

 - Fixed handling of `\r` when syncing db fields to translation.io [#523](https://github.com/portagenetwork/roadmap/issues/523)

## [3.3.1+portage-3.2.1] - 2023-10-19

### Fixed

 - Fixed guidance collapse issues [#467](https://github.com/portagenetwork/roadmap/issues/467)
 
 - Fixed display of ampersands in plan titles [#473](https://github.com/portagenetwork/roadmap/issues/473)

 - Fixed error handling in Dangerfile for missing CHANGELOG.md entry [#359](https://github.com/portagenetwork/roadmap/issues/359)

 - Fixed icons issues with the rebranding [#472](https://github.com/portagenetwork/roadmap/pull/472)

 - Fixed URL for API documentation v1 [#469](https://github.com/portagenetwork/roadmap/issues/469)

 - Removed duplicate line of code from application_controller.rb [#471](https://github.com/portagenetwork/roadmap/issues/471)

### Changed

 - Bump activerecord_json_validator from 2.1.3 to 2.1.5 [#483](https://github.com/portagenetwork/roadmap/pull/483)

 - Bump rubocop-rspec from 2.18.1 to 2.24.1 [#460](https://github.com/portagenetwork/roadmap/pull/460)

 - Bump zaru from 0.3.0 to 1.0.0 [#437](https://github.com/portagenetwork/roadmap/pull/437)

 - Bump better_errors from 2.9.1 to 2.10.1 [#436](https://github.com/portagenetwork/roadmap/pull/436)

 - Bump wicked_pdf from 2.6.3 to 2.7.0 [#438](https://github.com/portagenetwork/roadmap/pull/438)

 - Bump yard from 0.9.28 to 0.9.34 [#439](https://github.com/portagenetwork/roadmap/pull/439)

 - Bump mocha from 2.0.2 to 2.1.0 [#485](https://github.com/portagenetwork/roadmap/pull/485)

 - Bump @babel/traverse from 7.20.13 to 7.23.2 [#484](https://github.com/portagenetwork/roadmap/pull/484)

 - Bump devise from 4.9.2 to 4.9.3 [#480](https://github.com/portagenetwork/roadmap/pull/480)

 - Bump database_cleaner from 2.0.1 to 2.0.2 [#479](https://github.com/portagenetwork/roadmap/pull/479)

 - Bump jwt from 2.7.0 to 2.7.1 [#499](https://github.com/portagenetwork/roadmap/pull/499)

 - Bump activerecord-nulldb-adapter from 0.9.0 to 1.0.1 [#498](https://github.com/portagenetwork/roadmap/pull/498)

 - Bump pundit from 2.3.0 to 2.3.1 [#495](https://github.com/portagenetwork/roadmap/pull/495)
  
## [3.3.1+portage-3.2.0] - 2023-09-28

### Fixed

 - Fixed margin issues with the rebranding [#446](https://github.com/portagenetwork/roadmap/issues/446)

 - Fixed issue with the space between browser top and headers [#444](https://github.com/portagenetwork/roadmap/issues/444)

 - Users can now download public templates without being logged in [#335](https://github.com/portagenetwork/roadmap/issues/335)

 - Fixed equality checks in application_helper.rb [#355](https://github.com/portagenetwork/roadmap/issues/355)

 - Fixed landing page content and links for fr-CA locale [#405](https://github.com/portagenetwork/roadmap/pull/405)

 - Address missing French translations throughout application [#404](https://github.com/portagenetwork/roadmap/issues/404) and [#411](https://github.com/portagenetwork/roadmap/issues/411)

 - Removed repeated "Sign-up" and "Help" text in "About Us" [#407](https://github.com/portagenetwork/roadmap/issues/407)

 - Fixed broken "Help" link [#402](https://github.com/portagenetwork/roadmap/issues/412)

 - Fixed compatibility issues between Webdrivers Gem and Google Chrome v116+ [#427](https://github.com/portagenetwork/roadmap/pull/427)

 - Enable translations of Terms-Of-Use and Privacy-Policy pages [#429](https://github.com/portagenetwork/roadmap/pull/429)

 - Bump activerecord-nulldb-adapter from 0.8.0 to 0.9.0 [#386](https://github.com/portagenetwork/roadmap/pull/386)

 - Bump rubocop-thread_safety from 0.4.4 to 0.5.1 [#381](https://github.com/portagenetwork/roadmap/pull/381)

 - Bump recaptcha from 5.12.3 to 5.15.0 [#423](https://github.com/portagenetwork/roadmap/pull/423)

 - Bump rubocop-rails from 2.17.4 to 2.21.0 [#432](https://github.com/portagenetwork/roadmap/pull/432)

 - Improve 'Getting Started' Text For Signed In vs Non-Signed In Users [#433](https://github.com/portagenetwork/roadmap/pull/433)

### Changed

 - Updated Email and Hostname to correspond with rebranding changes [#450](https://github.com/portagenetwork/roadmap/issues/450) and [#456](https://github.com/portagenetwork/roadmap/issues/456)

 - Rebranding color changes (digital grey primary color) [#331](https://github.com/portagenetwork/roadmap/issues/331)

 - Merged [v3.3.1](https://github.com/DMPRoadmap/roadmap/releases/tag/v3.3.1)

 - Removed broken links to Portage Network pages [portagenetwork/roadmap#339](https://github.com/portagenetwork/roadmap/issues/339)

 - Updated emails's language is based on user's choice on UI, instead of system default [#196](https://github.com/portagenetwork/roadmap/issues/196)

 - Issue with 500 page error resue on Logo isseus on update of Organizations [#327](https://github.com/portagenetwork/roadmap/issues/327) and [#354](https://github.com/portagenetwork/roadmap/issues/354)

 - Edited terms-of-use and how-to-manage-your-data links to always be the localized routes in application_helper.rb [#397](https://github.com/portagenetwork/roadmap/issues/397)

 - update Danger to V9.3.1 [#360](https://github.com/portagenetwork/roadmap/pull/360)
 
 - Bump engine.io from 6.4.0 to 6.4.2 [#362](https://github.com/portagenetwork/roadmap/pull/362)
 
 - Bump socket.io-parser from 4.2.2 to 4.2.4 [#363](https://github.com/portagenetwork/roadmap/pull/363)
 
 - Bump semver from 5.7.1 to 5.7.2 [#366](https://github.com/portagenetwork/roadmap/pull/366)
 
 - Bump devise_invitable from 2.0.7 to 2.0.8 [#370](https://github.com/portagenetwork/roadmap/pull/370)
 
 - Bump devise from 4.8.1 to 4.9.2 [#371](https://github.com/portagenetwork/roadmap/pull/371)
 
 - Bump word-wrap from 1.2.3 to 1.2.4 [#376](https://github.com/portagenetwork/roadmap/pull/376)
 
 - Bump autoprefixer-rails from 10.4.7.0 to 10.4.13.0 [#377](https://github.com/portagenetwork/roadmap/pull/377)
 
 - Bump parallel from 1.22.1 to 1.23.0 [#378](https://github.com/portagenetwork/roadmap/pull/378)
 
 - Bump rack-mini-profiler from 3.0.0 to 3.1.0 [#391](https://github.com/portagenetwork/roadmap/pull/391)
 
 - Bump puma from 6.1.0 to 6.3.0 [#396](https://github.com/portagenetwork/roadmap/pull/396)

 - Bump puma from 6.3.0 to 6.3.1 [#422](https://github.com/portagenetwork/roadmap/pull/422)

 - Set Guidances/Comments toggle to opened by default [#425](https://github.com/portagenetwork/roadmap/pull/425)

## [3.1.0+portage-3.1.3] - 2023-06-13

### Fixed

 - Resolved problem when creating organisations [portagenetwork/roadmap#336](https://github.com/portagenetwork/roadmap/issues/336)

### Changed

 - Help-desk email now has correct address [portagenetwork/roadmap#338](https://github.com/portagenetwork/roadmap/issues/338)
 - Password reset mail no longer instructs the user against replying to email. [portagenetwork/roadmap#338](https://github.com/portagenetwork/roadmap/issues/338)

### Added

 - Translation entries for research ouput [portagenetwork/roadmap#332](https://github.com/portagenetwork/roadmap/issues/332)

## [3.1.0+portage-3.1.2] - 2023-03-28

### Fixed

- Resolved problem with updating plans [#333](https://github.com/portagenetwork/roadmap/issues/333)

## [3.1.0+portage-3.1.1] - 2023-02-24

### Fixed

- Fixed 500 error when admins try to downloading [#328](https://github.com/portagenetwork/roadmap/issues/328)

## [3.1.0+portage-3.1.0] - 2023-02-22

### Added

- In the project detail page, users can now specify a primary research domain for their project (e.g. Biology, Computer Science, Humanities, etc.). This information appears in the DMP's JSON as a 'tag'

- On the project detail page, users can now indicate and describe any ethical concerns that concern their research data. Clicking the checkbox will display a field to describe the concerns and a URL field to link to a report. This information appears in the DMP's JSON.

- Added a new 'Research Outputs' tab that allows users to specify information about their intended research outputs [#2738](https://github.com/portagenetwork/DMPRoadmap/issues/2738). User can specify the type (e.g. dataset, software, image, etc.), name and a description of the output, size (if applicable), whether or not it contains sensitive info or PII, what the initial access level will be (e.g. open, restricted, closed) and the anticipated publication date:

- ![Research Output](https://user-images.githubusercontent.com/1204467/162054150-e58ec156-18bb-4c2f-a516-1f28e14c3204.png "Research Outputs")

- Allowed user to select an appropriate license in the Research Outputs tab (note that the options come from the [SPDX license registry](https://spdx.org/licenses/)) [#2607](https://github.com/portagenetwork/DMPRoadmap/issues/2607)

- Allowed user to any metadata standards that will be followed (e.g. Dublin Core) in the Research Outputs tab (note that the list of standards comes from the [RDA Metadata standards catalog](https://rdamsc.bath.ac.uk/))  [#2798](https://github.com/portagenetwork/DMPRoadmap/issues/2798)

- Allowed users to select the repositories they intend to preserve the object in (e.g. Dryad, Zenodo, GitHub, or an institutional repository) in the Research Outputs tab (note that the list of repositories comes from the [re3data registry](https://www.re3data.org/)) [#2605](https://github.com/portagenetwork/DMPRoadmap/issues/2605)

- Added research outputs result to downloaded PDF file in a table format [#2812](https://github.com/portagenetwork/DMPRoadmap/issues/2812)

- Updated APIs to add research outputs result to the downloaded JSON file, which appears as 'Dataset' information

- Added helpdesk email address field to `Organisation's details`. This email will be used in the email signature for emails sent from the system (assuming the recipient of the email is a member of the same Organisation) [#3140](https://github.com/portagenetwork/DMPRoadmap/issues/3140)

- Added data migration rake tasks and migrated DMP Assistant database from MariaDB 10 to PostgreSQL 12 to better accommodate JSON format data

- Sandbox testing flag can be turned on/off so org admin can change *locally hosted* DMP Assistant to a sandbox testing environment

- Added rubocop test and code side support [#264](https://github.com/portagenetwork/roadmap/issues/264)

- Updated rubocop setting to disable the debug checking after upgrading to rubocop 1.45 [#316](https://github.com/portagenetwork/roadmap/issues/316)

- Added more clear error message to remind users not to fresh the page when the 'saving plan' process is stuck and the success message is not shown as expected [#241](https://github.com/portagenetwork/roadmap/issues/241)

- Added static page for server upgrading time [#310](https://github.com/portagenetwork/roadmap/issues/310)

- Make the comments/guidances are collapsible to give the researcher more space to see their answers [#3123](https://github.com/portagenetwork/DMPRoadmap/issues/3123)

### Changed

- DMP Assistant migrated all data from MariaDB 10 to PostgreSQL 12

- Updated all Gems and JS dependencies

- Used excel sheet to track the upgrading process [#187](https://github.com/portagenetwork/roadmap/issues/187)

- Updated the french translations for the Portage template for systematic reviews [#269](https://github.com/portagenetwork/roadmap/issues/269)

- Adjusted Dockerfile.Production to move `rails assets:precompile` step to `docker-compose.yml` file [#282](https://github.com/portagenetwork/roadmap/issues/282)

- Relived memory load in the translation syncing process by adjusting configuration so that only code in the `app` folder will be scanned and translated [#313](https://github.com/portagenetwork/roadmap/issues/313)

- Adjusted customized translation.io source code to add `unscoped` method for the necessary table to fit PostgreSQL syntax (https://github.com/lagoan/translation_io_rails/pull/2)

### Fixed

- Reversed `perm_helper.rb` changes to reduce translation.io sync memory pressure and added rubocop exception for `translation.rb` [#315](https://github.com/portagenetwork/roadmap/issues/315)

- Unmanaged organization will not show in all org selectors except the creating new organization page [#260](https://github.com/portagenetwork/roadmap/issues/260)

- Allowed contributors to choose organizations [#273](https://github.com/portagenetwork/roadmap/issues/273)

- Allowed admin to see unmanaged org name when creating new org to avoid duplication [#275](https://github.com/portagenetwork/roadmap/issues/275)

- Force Github actions using Ubuntu 20.04 to fix wkhtmltopdf-binary issue [#266](https://github.com/portagenetwork/roadmap/issues/266)

- Clarified of String and Array behavior for plan exports [#268](https://github.com/portagenetwork/roadmap/issues/268)

- Fixed the error that `app.pot` headers accidentals appear in the empty text box of *writing plans* area [#308](https://github.com/portagenetwork/roadmap/issues/308)

- Fixed for pagination of plans retrieved using the REST API V0 [#3105](https://github.com/portagenetwork/DMPRoadmap/issues/3105)

- Security vulnerability patches [#3100](https://github.com/portagenetwork/DMPRoadmap/issues/3100), [#3097](https://github.com/portagenetwork/DMPRoadmap/issues/3097), [#3093](https://github.com/portagenetwork/DMPRoadmap/issues/3093), [#3077](https://github.com/portagenetwork/DMPRoadmap/issues/3077)

- Fixed issues/inconsistencies with policies [#3084](https://github.com/portagenetwork/DMPRoadmap/issues/3084) [#3099](https://github.com/portagenetwork/DMPRoadmap/issues/3099)

- Fix for issue downloading PDFs [#3054](https://github.com/portagenetwork/DMPRoadmap/issues/3054)[#3049](https://github.com/portagenetwork/DMPRoadmap/issues/3049) [#3098](https://github.com/portagenetwork/DMPRoadmap/issues/3098)

- Fix for issue displaying users as collaborators on a plan after they have removed themselves Fix for issue downloading PDFs [#3095](https://github.com/portagenetwork/DMPRoadmap/issues/3095)

- Fix for API v0 not supplying the owner email address Fix for issue downloading PDFs [#3094](https://github.com/portagenetwork/DMPRoadmap/issues/3094)

- Fix for bug preventing Super Admins from creating new Orgs [#3091](https://github.com/portagenetwork/DMPRoadmap/issues/3091)

- Fix for issue causing deleted plans to appear in the Org Admin list of plans [#3087](https://github.com/portagenetwork/DMPRoadmap/issues/3087)

- Fix for CSV downloads [#3085](https://github.com/portagenetwork/DMPRoadmap/issues/3085)[#3075](https://github.com/portagenetwork/DMPRoadmap/issues/3075)

- Fix for pagination and search on the Admin plans page [#3069](https://github.com/portagenetwork/DMPRoadmap/issues/3069) [#3073](https://github.com/portagenetwork/DMPRoadmap/issues/3073)

- Fix for strings that were not included in translation content [#3081](https://github.com/portagenetwork/DMPRoadmap/issues/3081)[#3050](https://github.com/portagenetwork/DMPRoadmap/issues/3050)

- Fix for issue with contributor org logic not adhering to the restrict_orgs config flag [#3078](https://github.com/portagenetwork/DMPRoadmap/issues/3078)[#3060](https://github.com/portagenetwork/DMPRoadmap/issues/3060)

- Fix for adding contributors [#3071](https://github.com/portagenetwork/DMPRoadmap/issues/3071)

- Removed phone number field from contributor page  [#3067](https://github.com/portagenetwork/DMPRoadmap/issues/3067)

- Fixed issue with merging users  [#3065](https://github.com/portagenetwork/DMPRoadmap/issues/3065)

- Fixed issue with emails  [#3052](https://github.com/portagenetwork/DMPRoadmap/issues/3052)

- Fix for users unable to see API page  [#3047](https://github.com/portagenetwork/DMPRoadmap/issues/3047)

- Upgraded Rubocop and updated all files accordingly  [#3048](https://github.com/portagenetwork/DMPRoadmap/issues/3048)  [#3045](https://github.com/portagenetwork/DMPRoadmap/issues/3045)

- Fixed an issue that was preventing Org Admins from seeing the 'Share' tab  [#3131](https://github.com/portagenetwork/DMPRoadmap/issues/3131)

- Fixed an issue that was causing errors when Org Admins tried to save changes to a template  [#3071](https://github.com/portagenetwork/DMPRoadmap/issues/3038)

- Patched an issue that continued to show users as collaborators on a Plan's Share tab even after they had removed themselves from the Plan  [#3126](https://github.com/portagenetwork/DMPRoadmap/issues/3126)

- Fixed an issue that was causing TinyMCE editors to have an incorrect size when they initially load  [#3141](https://github.com/portagenetwork/DMPRoadmap/issues/3141)

- Various fixes for the APIs

- Patched issue that was always using the default template when creating a new DMP in API v1  [#3137](https://github.com/portagenetwork/DMPRoadmap/issues/3137)

- Fixed an issue that was preventing plans from being created via API v0  [#3135](https://github.com/portagenetwork/DMPRoadmap/issues/3135)

- Addressed an issue that was preventing users from being unassigned from a department in API v0  [#3132](https://github.com/portagenetwork/DMPRoadmap/issues/3132)

- Reverted change to our use of string format tokens that were made during an upgrade of Rubocop. The preferred format is once again Some %{variable_name} text  [#3138](https://github.com/portagenetwork/DMPRoadmap/issues/3128)

- Fixed some potential PDF downloading problems

- Updated Github Actions to use specified node version [#319](https://github.com/portagenetwork/roadmap/issues/319)


## [3.0.4+portage-3.0.16] - 2022-12-14

### Changed

- Upgrade rails-html-sanitizer to 1.4.4 and loofah to 2.19.1 to prevent possible XSS vulnerability attack and other security problems(https://github.com/rails/rails-html-sanitizer/security/advisories/GHSA-mcvf-2q2m-x72m, https://github.com/flavorjones/loofah/security/advisories/GHSA-486f-hjj9-9vhh)

- Upgrade rubocop-rails_config to 1.12.0

- Upgrade selenium-webdriver to 4.7.1

### Fixed

- Fixed Github action ruby 'version not valid' issue [#265](https://github.com/portagenetwork/roadmap/issues/265)

- Fixed Dangerfile configuration issue (https://github.com/DMPRoadmap/roadmap/pull/3263)

- Fixed spec_helper.rb file to remove undefined Capybara::Webmock method

## [3.0.4+portage-3.0.15] - 2022-11-04

### Changed

- Upgrade ruby 2.6.9 to 2.7.6 due to a bug fix of ruby for XCode 14 (https://bugs.ruby-lang.org/issues/18912) was only pushed to ruby >=2.7

- Updated Docker.production file to fix a rake issue when pushing to docker

### Fixed

- Fixed the bug that some users saw 'Tried to Load Specific Class: Symbol' error message when moving to Download tab [#240](https://github.com/portagenetwork/roadmap/issues/240)

## [3.0.4+portage-3.0.14] - 2022-08-26

### Added

- Added french translation of the Request Feedback email [#188](https://github.com/portagenetwork/roadmap/issues/188)

### Fixed

- Allowed user to proceed after checking 'No primary research institution' checkbox when creating a new plan [#221](https://github.com/portagenetwork/roadmap/issues/221)

- Removed unmanaged organizations from the selection list when a user creates a new plan [#191](https://github.com/portagenetwork/roadmap/issues/191)

## [3.0.4+portage-3.0.13] - 2022-07-13

### Changed

- Upgraded Rails to 5.2.8.1 to fix the Possible RCE escalation bug with Serialized Columns in Active Record in Rails 5.2.6 (https://groups.google.com/g/rubyonrails-security/c/MmFO3LYQE8U/m/q9axtXheAQAJ)

- Along with the Rails upgrade, upgraded activejob, activeview, activemodal, activestorage, activepack, activerecord, activesupport, actioncable, actionmailer, actionjob, actionview and railsties to 5.2.8.1

- Along with the Rails upgrade, upgraded i18n to 1.8.11

- Along with the Rails upgrade, upgraded rack to 2.2.4

- Along with the Rails upgrade, upgraded sprockets to 4.0.3

- Along with the Rails upgrade, upgraded  marcel to 1.0.2

- Along with the Rails upgrade, upgraded mini_mine to 1.1.2

- Along with the Rails upgrade, upgraded concurrent-ruby to 1.1.10

### Added

- Added contributors to the plan's cover page (if there is any) [#202](https://github.com/portagenetwork/roadmap/issues/202)

- Added plan title to CSV exported file

### Fixed

- Added bootstrap-select stylesheet back after version 3 upgrade to fix the option-picker UI bug [#195](https://github.com/portagenetwork/roadmap/issues/195)

## [3.0.4+portage-3.0.12] - 2022-05-12

### Added

- Updated the Term of Usage page and Privacy Policy information

## [3.0.4+portage-3.0.11] - 2022-04-14

### Fixed

- Fixed password reset link
- Adjusted accordion javascript for a different user case [#166](https://github.com/portagenetwork/roadmap/issues/166)

### Changed

- Nokogiri upgrade to 1.13.4
- Moment upgrade to 2.29.2

## [3.0.4+portage-3.0.10] - 2022-04-12

### Fixed

- Fixed branding.yml for sandbox testing

### Changed

- Test JSON format plan download

## [3.0.4+portage-3.0.9] - 2022-04-11

### Fixed

- Fixed sandbox setting based on the server configuration

## [3.0.4+portage-3.0.8] - 2022-04-08

### Fixed

- Fixed invalid org selection when new user accept invitation [#177](https://github.com/portagenetwork/roadmap/issues/177)

## [3.0.4+portage-3.0.7] - 2022-04-05

### Added

- Added feature flag for sandbox testing [#159](https://github.com/portagenetwork/roadmap/issues/159)
- Adjust seed files for different environment and prepare seed files for sandbox testing

### Fixed

- Change plan identifier field and add it to export [#158](https://github.com/portagenetwork/roadmap/issues/158)
- Change contact email to support@portagenetwork.ca [#172](https://github.com/portagenetwork/roadmap/issues/172)

## [3.0.4+portage-3.0.6] - 2022-03-23

### Fixed
   - Usage statistics page now shows correct data [#164](https://github.com/portagenetwork/roadmap/issues/164)

## [3.0.4+portage-3.0.5] - 2022-03-07

### Fixed
   - Fixed pdf/html/docx/txt download issue [#153](https://github.com/portagenetwork/roadmap/issues/153)

## [3.0.4+portage-3.0.4] - 2022-02-25
  - Update translation for some wording

## [3.0.4+portage-3.0.3] - 2020-02-24

  ### Changed
   - Updated Alliance information
   - Updated branding
   - Updated translation files

  ### Fixed
   - Docker workflow to build image on release

## [3.0.4+portage-3.0.2] - 2020-02-10

  ### Changed
   - Update footer for the new Alliance branding
  ### Added
  - Danger workflow to automate code review tasks

## [3.0.4+portage-3.0.1] - 2022-01-17

### Changed
  - Update mysql installation process for the Github action

## [3.0.4+portage-3.0.0] - 2022-01-17

### Changed
  - Update mysql installation process for the Github action

## [3.0.4+portage-3.0.0] - 2021-12-09

### Updated
 - Upgrade Ruby to 2.6.6
 - Upgrade Bundler to 2.2.24.
 - Upgrade node to 12
 - Upgrade node-sass to 7.0.0

### Added
 - Add content based on the feedback from our French language review
 - Add translated read access method for Template and Plan content
 - Add rake tasks to export and import templates
 - Include application name on translation
 - Add locale permanency after logout
 - Add tinymce translations
 - Add localized DMP assistant logo
 - Add translation for Theme content
 - Add configuration for ActionMailer to use SMTP
 - Add crafted favicon to be served as static content
 - Render a 404 error page when record is not found
 - Add configuration for rollbar calls
 - Add configuration for wicked_pdf proxy
 - Add Google analytics
 - Add rake tasks to remove span accounts

### Removed
 - Remove references of "Do not reply" on mailers as we are now expecting replies from application emails
 - Remove all calls trying to translate an empty string
 - Remove autofill for plan grant number
 - Remove institutional credential from profile edit as we are not currently using Shibboleth
 - Deactivate Shibboleth authentication

### Changed
 - Update response to reset password email to suggest a direct response
 - Update translation files
 - Change the "number to text" js package to a newer version with continued support
 - Change translation.io gem to our own customization to allow database translation support
 - Change French date format localization
 - Update static content pages
 - Change CSS Branding for navbar
 - Replace portage orange in favor of white as 2nd UI color
 - Change logger to syslog


### Fixed
 - Fix random log warnings
 - Address problems with tests using tinymce
 - Fix locales tests
 - Fix issues with tests taking too long
 - Fix support for nulldb adapter
 - Fix 500 error when downloading usage statistics

## [2.1.3+portage-1.0.19] - 2021-09-15

### Fixed
  - Usage statistics now show the statistics for the current user's organization
  - Tab widget nOW working on user profile view [#73](https://github.com/portagenetwork/roadmap/issues/73)
## [2.1.3+portage-1.0.17] - 2021-08-11

### Added
 - Configuration for direct_link protocol
 - Configuration for default funder name

## [2.1.3+portage-1.0.16] - 2021-07-21

## [2.1.3+portage-1.0.14] - 2021-06-17

### Fixed
 - Remove duplicate listing of default template when chosen organization has a customized default template

## [2.1.3+portage-1.0.13] - 2021-06-16
### Changed
 - Applied changes in ordering requested by the Admin Guide Working Group
 - Changes to Canadian spelling
## [2.1.3+portage-1.0.10] - 2021-06-03

### Fixed
 - Removed references to organizations customized template and to default template
 - Restored missing institutional templates
## [2.1.3+portage-1.0.10] - 2021-06-03

### Added
 - Added functionality for super administrators to create usage statistics filters including all organizations.
 - Added logos on footer for new affiliated organizations.

### Changed
 - Changed landing page content to make it more user friendly.
 - Changed footer and header layout.
 - Logo on error pages now show DMP Assistant bi-lingual logo.

### Fixed
 - Creating a plan from a direct link does no longer create a 422 error.

## [2.1.3+portage-1.0.10] - 2021-04-22

### Changed
 - Changed configuration to make sure we are using ruby 2.5.9
 - Made the option for adding cover sheet for plan options default to true
 - Changed configuration to restrict organization administrators from reading private plans

## [2.1.3+portage-1.0.9] - 2021-04-19

### Fixed
 - Fix bug when copying new plan url on template paginated view

### Removed
 - Pulled unused javascript validation when creating a new user

### Changed
 - Changed redirect path when error in signup form

## [2.1.3+portage-1.0.8] - 2021-04-06

### Added
 - Include reCAPTCHA Security check for account creation
 - Add feature to make Templates public

### Fixed
 - Arrange organization links in header layout

## [2.1.3+portage-1.0.7] - 2021-03-08

### Added
 - Add visibility options for plans
 - Make public plans downloadable

## [2.1.3+portage-1.0.6] - 2021-03-02

### Fixed
 - Vertical alignment for organization name

## [2.1.3+portage-1.0.5] - 2021-03-02

### Added
 - Add content to help page

### Changed
 - Update translation files

### Fixed
 - Fix small errors for French content

## [2.1.3+portage-1.0.4] - 2021-02-28

### Fixed
 - Fix problem when searching for templates when using raw SQL queries

## [2.1.3+portage-1.0.3] - 2021-02-27

### Changed
 - Update translation files

### Fixed
 - Fix bug with Question options not being translated

## [2.1.3+portage-1.0.2] - 2021-02-26

### Changed
 - Update translation files
### Fixed
 - Fix bug when importing templates from rake task

## [2.1.3+portage-1.0.1] - 2021-02-24

### Added
 - Add content to landing page with new links and french versions for same sites

### Changed
 - Change database connection encoding

## [2.1.3+portage-1.0.0] - 2021-02-16

### Added
 - Add content based on the feedback from our French language review
 - Add translated read access method for Template and Plan content
 - Add rake tasks to export and import templates
 - Include application name on translation
 - Add locale permanency after logout
 - Add tinymce translations
 - Add localized DMP assistant logo
 - Add translation for Theme content
 - Add configuration for ActionMailer to use SMTP
 - Add crafted favicon to be served as static content
 - Render a 404 error page when record is not found
 - Add configuration for rollbar calls
 - Add configuration for wicked_pdf proxy
 - Add Google analytics
 - Add rake tasks to remove span accounts
 - Add sandbox database environment

### Removed
 - Remove references of "Do not reply" on mailers as we are now expecting replies from application emails
 - Remove all calls trying to translate an empty string
 - Remove autofill for plan grant number
 - Remove institutional credential from profile edit as we are not currently using Shibboleth
 - Deactivate Shibboleth authentication

### Changed
 - Update response to reset password email to suggest a direct response
 - Update translation files
 - Change the "number to text" js package to a newer version with continued support
 - Change translation.io gem to our own customization to allow database translation support
 - Change French date format localization
 - Update static content pages
 - Change CSS Branding for navbar
 - Replace portage orange in favor of white as 2nd UI color
 - Change logger to syslog
 - Updated Broken links.

### Fixed
 - Fix random log warnings
 - Address problems with tests using tinymce
 - Fix locales tests
 - Fix issues with tests taking too long
 - Fix support for nulldb adapter
 - Fix 500 error when downloading usage statistics
 - Fix name of downloaded usage file
 - Allow organizational admin to see the download button in 'Statisctics on Users' and 'Statistics on Tempalte' accordions
 - Upgrade node-sass to 7, node to 12 and adjust eslint test to use Github default action
