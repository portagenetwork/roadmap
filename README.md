# DMP Assistant

[![Actions Brakeman](https://github.com/portagenetwork/roadmap/workflows/Brakeman/badge.svg)](https://github.com/portagenetwork/roadmap/actions)
[![Actions ESLint](https://github.com/portagenetwork/roadmap/workflows/ESLint/badge.svg)](https://github.com/portagenetwork/roadmap/actions)
[![Actions Test - MySQL](https://github.com/portagenetwork/roadmap/workflows/Tests%20-%20MySQL/badge.svg)](https://github.com/portagenetwork/roadmap/actions)
[![MIT License](https://img.shields.io/github/license/portagenetwork/roadmap)](https://github.com/portagenetwork/roadmap/blob/deployment-portage/LICENSE.md)
[![GitHub release](https://img.shields.io/github/v/release/portagenetwork/roadmap.svg)](https://GitHub.com/portagenetwork/roadmap/releases/)
[![GitHub issues](https://img.shields.io/github/issues/portagenetwork/roadmap.svg)](https://GitHub.com/portagenetwork/roadmap/issues/)

> Developed by the Digital Research Alliance of Canada (the Alliance; Portage Network) in collaboration with host institution University of Alberta, DMP Assistant repo is a **fork** of the <a href="https://github.com/DMPRoadmap/roadmap">DMP Roadmap codebase</a>, which is management and developed jointly provided by the Digital Curation Centre (DCC) and the University of California Curation Center (UC3).

---
- [Overview](#overview)
- [Installation](#installation)
  * [Pre-requisites](#pre-requisites)
  * [Troubleshooting](#troubleshooting)
  * [Support](#support)
- [About DMP Roadmap](#about-dmp-roadmap)
- [Contributing](#contributing)
---

## Overview

The DMP Assistant is a national, online, bilingual data management planning tool developed by <a href="https://alliancecan.ca">the Digital Research Alliance of Canada (the Alliance; Portage Network)</a> in collaboration with host institution University of Alberta to assist researchers in preparing data management plans (DMPs). This tool is freely available to all researchers, and develops a DMP through a series of key data management questions, supported by best-practice guidance and examples.

The DMP Assistant was adapted from the <a href="https://dcc.ac.uk/">Digital Curation Centre (DCC)</a>’s <a href="https://dmponline.dcc.ac.uk/">DMPonline</a> tool, and uses the <a href="https://github.com/DMPRoadmap/roadmap">DMP Roadmap</a> codebase developed by DCC and <a href="https://assistant.portagenetwork.ca/%20https://cdlib.org/services/uc3/">the University of California Curation Center (UC3)</a>.

## Installation

See the [Installation Guide](https://github.com/portagenetwork/roadmap/wiki/Installation) on the Wiki.

### Pre-requisites

DMP Assistant is a Ruby on Rails application and you will need to have:
* Ruby = 2.6.6 - 2.6.9
* Rails = 5
* MySQL >= 8.0

Further detail on how to install Ruby on Rails applications are available from the Ruby on Rails site: http://rubyonrails.org.

Further details on how to install MySQL and create your first user and database. Be sure to follow the instructions for your particular environment.
* Install: http://dev.mysql.com/downloads/mysql/
* Create a user: http://dev.mysql.com/doc/refman/8.0/en/create-user.html
* Create the database: http://dev.mysql.com/doc/refman/8.0/en/creating-database.html

You may also find the following resources handy:

* The Getting Started Guide: http://guides.rubyonrails.org/getting_started.html
* Ruby on Rails Tutorial Book: http://www.railstutorial.org/

### Troubleshooting

See the [Troubleshooting Guide](https://github.com/portagenetwork/roadmap/wiki/Troubleshooting) on the Wiki.

### Support

Issues should be reported here on [Github Issues](https://github.com/portagenetwork/roadmap/issues)
Please be advised though that we can only provide limited support for your local installations.
Any security patches and bugfixes will be applied to the most recent version, and we will endeavour to support migrations to the current release.

## About DMP Roadmap

DMP Roadmap is a Data Management Planning tool. Management and development of DMP Roadmap is jointly provided by the Digital Curation Centre (DCC), http://www.dcc.ac.uk/, and the University of California Curation Center (UC3), http://www.cdlib.org/services/uc3/.

The tool has four main functions:

1. To help create and maintain different versions of Data Management Plans;
2. To provide useful guidance on data management issues and how to meet research funders' requirements;
3. To export attractive and useful plans in a variety of formats;
4. To allow collaborative work when creating Data Management Plans.

## Contributing

If you would like to contribute to the project. Please follow these steps to submit a contribution:
* Comment on the Github issue (or create one if one does not exist) and let us know that you're working on it.
* Fork the project (if you have not already) or rebase your fork so that it is up to date with the current repository's '_**development**_' branch
* Create a new branch in your fork. This will ensure that you are able to work at your own pace and continue to pull in any updates made to this project.
* Make your changes in the new branch
* When you have finished your work, make sure that your version of the '_**development**_' branch is still up to date with this project. Then merge your new branch into your '_**development**_' branch.
* Then create a new Pull Request (PR) from your branch to this project's '_**development**_' branch in GitHub
* The project team will then review your PR and communicate with you to convey any additional changes that would ensure that your work adheres to our guidelines.

See the [Contribution Guide](https://github.com/portagenetwork/roadmap/blob/development/CONTRIBUTING.md) on the Wiki for more details.

<br/>
<table style="border:none;"><tr>
<td style="border:none;" ><a href="https://alliancecan.ca/"><img style="max-width: 300px" src="https://alliancecan.ca/assets/ui/Logo.svg" /></a></td>
<td style="border:none;" ><a href="https://portagenetwork.ca/"><img style="max-width: 150px" src="https://portagenetwork.ca/wp-content/uploads/2020/06/Portage_logo_Tagline_rgb_bilingual.png" /></a></td>
<td style="border:none;" ><a href="https://assistant.portagenetwork.ca/"><img style="max-width: 100px" src="https://assistant.portagenetwork.ca/assets/dmp_logo_en_CA-5c33553d0405a518232ce38f3ac75bed9ac72d99753753117a1b3d68b1c35554.png" /></a></td>
</tr></table>