# frozen_string_literal: true

module Orgs
  # Invoked by the `orgs:cleanup_junk_funders` rake task.
  # Finds "junk funders" and sets `plan.funder_id = nil` for their associated plans.
  # - Junk funders are orgs meeting the following criteria:
  #   1) Have `org.id == plan.funder_id` as their only association
  #   2) Have a "junk" name (see JUNK_FUNDER_NAMES)'
  module CleanupJunkFundersService
    JUNK_FUNDER_NAMES = [
      '-', '1010-A', '123', '12345', '<Who is funding this project?>', 'All lab funding',
      'Anonymous foundation', 'Benny', 'Big Money Co.', 'Bill Gates', 'Bruce "Not Batman"Wayne',
      'Deep Pockets', 'District funded', 'Elon Musk', 'Elon Musk hopefully', 'Funded', 'Funder',
      'Funder 1', 'Funding Agency #1', 'Funding Organization', 'Grant', 'I highly doubt that',
      'Idk', 'Info not provided', 'Internal', 'Internal Funding', 'Jeff Bezos', 'Jesus',
      'Joe Biden', 'John Doe', 'Juniper (cat)', 'Karin', 'Lawsuit', 'LoL project - NASA',
      'Many...', 'Marcus Closen of the DRAC', 'Me', 'Me, myself and I', 'Michelle Obama', 'Mock',
      'Mock Funder', 'Mr. Funder Man', 'Multiple sources', 'Myself', 'N', 'N.A.', 'N/', 'N/A',
      'N/a', 'NA', 'Nancy', 'Nerisa D', 'No Funder', 'No funder', 'No funding', 'No funding.',
      "No one :'(", 'No one in particular', 'None required', 'Not applicable',
      'Not applicable at present', 'Not funded', 'Not sure', 'Partner', 'Pending', 'Personal',
      'Personally', 'Portage with spaces Network', 'Private', 'Self', 'Self Funded',
      'Self and potential scholarship', 'Self-Funded', 'Self-funded', 'Show Me the Green', 'Sure',
      'TBA', 'TBD', 'Test', 'The Bank', 'This funder has spaces', 'To be defined', 'Uknown',
      'Unfunded', 'Unsure', 'Various', 'Zeus', 'abcdef', 'agri', 'aqua chiara', 'asdaddsa',
      'aucun', 'aucuns', 'christian', 'confidential', 'efwewef', 'fgd', 'financement interne',
      'free funder', 'funder name', 'funder-name', 'funding number needed', 'hi',
      'is this organization', 'ma big fat wallet', 'me', 'moi meme', 'mr donator',
      'myself', 'n/a', 'nil', 'no fund', 'non identified', 'none', 'pev', 'self-funded', 'test',
      'test funder today', 'unfunded', 'vbp', 'vxzvxvc', 'x', 'xxx'
    ].freeze

    extend self

    def run(dry_run: false)
      junk_funder_ids = fetch_junk_funder_ids
      associated_plans = Plan.where(funder_id: junk_funder_ids)

      puts "Found #{junk_funder_ids.size} junk funder orgs and #{associated_plans.size} associated plans."

      return if dry_run

      updated_count = associated_plans.update_all(funder_id: nil)
      puts "Updated #{updated_count} of the associated plans to `plan.funder_id = nil`."
    end

    private

    def fetch_junk_funder_ids
      # `base` is the base query for orphan orgs with the funded_plans query omitted.
      base = Orgs::AssociationInspector.orphan_orgs(allow_funded_plans_association: true)
      # Rather than true orphans, we want orgs that only have the plans.funder association
      # Of those orgs, we only want the ones whose names are included in JUNK_FUNDER_NAMES
      base.joins('INNER JOIN plans funded_plans ON funded_plans.funder_id = orgs.id')
          .where(name: JUNK_FUNDER_NAMES)
          .distinct
          .pluck(:id)
    end
  end
end
