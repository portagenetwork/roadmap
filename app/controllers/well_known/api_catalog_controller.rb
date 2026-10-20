# frozen_string_literal: true

module WellKnown
  # Publishes the RFC 9727 API catalog (Linkset JSON) for the Common MaDMP API.
  class ApiCatalogController < ActionController::API
    HOST_URL = Rails.application.secrets.omniauth_full_host
    CONTENT_TYPE = 'application/linkset+json; profile="https://www.rfc-editor.org/info/rfc9727"'
    OPENAPI_TYPE = 'application/vnd.oai.openapi'
    HTML_TYPE = 'text/html'
    COMMON_MADMP_BASE_URL = "#{HOST_URL}/api/madmp".freeze
    V2_API_URL = "#{HOST_URL}/api/v2".freeze
    COMMON_SPEC_URL = 'https://raw.githubusercontent.com/RDA-DMP-Common/common-madmp-api/refs/tags/v1.0.0/openapi.yaml'
    V2_API_DOCS_URL = 'https://github.com/portagenetwork/roadmap/wiki/API-v2-Documentation'
    OAUTH_DOCS_URL = 'https://github.com/portagenetwork/roadmap/wiki/OAuth-2.0-Authentication'

    before_action :set_common_headers

    # GET /.well-known/api-catalog
    def show
      render json: linkset, content_type: CONTENT_TYPE
    end

    # HEAD /.well-known/api-catalog
    def head_catalog
      head :ok, content_type: CONTENT_TYPE
    end

    private

    # Headers shared by GET and HEAD so both responses are identical.
    def set_common_headers
      expires_in 1.hour, public: true
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Link'] = link_header
    end

    def catalog_url
      "#{HOST_URL}/.well-known/api-catalog"
    end

    def link_header
      "<#{catalog_url}>; rel=\"api-catalog\""
    end

    def common_madmp_docs
      [{ href: OAUTH_DOCS_URL, type: HTML_TYPE }]
    end

    def v2_docs
      [
        { href: V2_API_DOCS_URL, type: HTML_TYPE },
        { href: OAUTH_DOCS_URL, type: HTML_TYPE }
      ]
    end

    def linkset
      {
        linkset: [
          { anchor: catalog_url, item: [{ href: COMMON_MADMP_BASE_URL }, { href: V2_API_URL }] },
          {
            anchor: COMMON_MADMP_BASE_URL,
            'service-desc': [{ href: COMMON_SPEC_URL, type: OPENAPI_TYPE }],
            'service-doc': common_madmp_docs
          },
          { anchor: V2_API_URL, 'service-doc': v2_docs }
        ]
      }
    end
  end
end
