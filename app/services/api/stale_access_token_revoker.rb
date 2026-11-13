# frozen_string_literal: true

module Api
  # Revokes Doorkeeper access tokens (and therefore their refresh tokens) that
  # expired more than `older_than` ago, so that `doorkeeper:db:cleanup` can
  # delete them. Doorkeeper refresh tokens never expire on their own, which
  # leaves rows that the standard cleanup will not remove.
  #
  # Returns:
  # - The number of tokens revoked
  class StaleAccessTokenRevoker
    def initialize(older_than: 3.months)
      @older_than = older_than
    end

    def call
      now = Time.current

      Doorkeeper::AccessToken
        .where(revoked_at: nil)
        .where.not(expires_in: nil)
        # Compare token expiry against the retention cutoff; equality is retained.
        .where("created_at + (expires_in * INTERVAL '1 second') < ?", now - @older_than)
        .update_all(revoked_at: now)
    end
  end
end
